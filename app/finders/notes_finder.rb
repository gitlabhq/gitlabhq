# frozen_string_literal: true

class NotesFinder
  FETCH_OVERLAP = 5.seconds

  attr_reader :target_type

  # Used to filter Notes
  # When used with target_type and target_id this returns notes specifically for the controller
  #
  # Arguments:
  #   current_user - which user check authorizations with
  #   project - which project to look for notes on
  #   params:
  #     target: noteable
  #     target_type: string
  #     target_id: integer
  #     last_fetched_at: time
  #     search: string
  #     sort: string
  #
  def initialize(current_user, params = {})
    @project = params[:project]
    @current_user = current_user
    @params = params.dup
    @target_type = @params[:target_type]
  end

  def execute
    notes = init_collection
    notes = since_fetch_at(notes)
    notes = notes.with_notes_filter(@params[:notes_filter]) if notes_filter?
    notes = redact_internal(notes)
    notes = notes.without_hidden if without_hidden_notes?
    sort(notes)
  end

  def target
    return @target if defined?(@target)

    if target_given?
      use_explicit_target
    else
      find_target_by_type_and_ids
    end
  end

  private

  def target_given?
    @params.key?(:target)
  end

  def use_explicit_target
    @target = @params[:target]
    @target_type = @target.class.name.underscore

    @target
  end

  def find_target_by_type_and_ids
    target_id   = @params[:target_id]
    target_iid  = @params[:target_iid]

    return @target = nil unless target_type
    return @target = nil unless target_id || target_iid

    @target =
      if target_type == "commit"
        @project.commit(target_id) if Ability.allowed?(@current_user, :read_code, @project)
      else
        noteable_for_type_by_id(target_type, target_id, target_iid)
      end
  end

  def noteable_for_type_by_id(type, id, iid)
    query = if id
              { id: id }
            else
              { iid: iid }
            end

    # the reads finder needs to query by vulnerability_id
    return noteables_for_type(type).find_by!(vulnerability_id: query[:id]) if type == 'vulnerability' # rubocop: disable CodeReuse/ActiveRecord

    noteables_for_type(type).find_by!(query) # rubocop: disable CodeReuse/ActiveRecord
  end

  def init_collection
    if target
      notes_on_target
    elsif target_type
      notes_of_target_type
    else
      notes_of_any_type
    end
  end

  def notes_of_target_type
    notes = notes_for_type(target_type)

    search(notes)
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def notes_of_any_type
    types = %w[commit issue merge_request snippet]
    note_relations = types.map { |t| notes_for_type(t) }
    note_relations.map! { |notes| search(notes) }
    UnionFinder.new.find_union(note_relations, Note.includes(:author)) # rubocop: disable CodeReuse/Finder
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def noteables_for_type(noteable_type)
    case noteable_type
    when "issue"
      IssuesFinder.new(@current_user, project_id: @project.id).execute # rubocop: disable CodeReuse/Finder
    when "merge_request"
      MergeRequestsFinder.new(@current_user, project_id: @project.id).execute # rubocop: disable CodeReuse/Finder
    when "snippet", "project_snippet"
      SnippetsFinder.new(@current_user, project: @project).execute # rubocop: disable CodeReuse/Finder
    when "personal_snippet"
      SnippetsFinder.new(@current_user, only_personal: true).execute # rubocop: disable CodeReuse/Finder
    when "wiki_page/meta"
      WikiPage::Meta.for_project(@project)
    else
      raise "invalid target_type '#{noteable_type}'"
    end
  end

  # rubocop: disable CodeReuse/ActiveRecord
  def notes_for_type(noteable_type)
    if noteable_type == "commit"
      if Ability.allowed?(@current_user, :read_code, @project)
        @project.notes.where(noteable_type: 'Commit')
      else
        Note.none
      end
    else
      finder = noteables_for_type(noteable_type)
      @project.notes.where(noteable_type: finder.base_class.name, noteable_id: finder.reorder(nil))
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  def notes_on_target
    if target.respond_to?(:related_notes)
      target.related_notes
    else
      target.notes
    end
  end

  # Searches for notes matching the given query.
  #
  # This method uses ILIKE on PostgreSQL.
  #
  def search(notes)
    query = @params[:search]
    return notes unless query

    notes.search(query)
  end

  # Notes changed since last fetch
  def since_fetch_at(notes)
    return notes unless @params[:last_fetched_at]

    # Default to 0 to remain compatible with old clients
    last_fetched_at = @params.fetch(:last_fetched_at, Time.at(0))

    # Use overlapping intervals to avoid worrying about race conditions
    last_fetched_at -= FETCH_OVERLAP

    notes.updated_after(last_fetched_at)
  end

  def notes_filter?
    @params[:notes_filter].present?
  end

  def sort(notes)
    sort = @params[:sort].presence

    return notes.order_created_at_id_asc unless sort

    notes.order_by(sort)
  end

  def redact_internal(notes)
    subject = @project || target
    return notes if Ability.allowed?(@current_user, :read_internal_note, subject)

    notes.not_internal
  end

  def without_hidden_notes?
    return false if @current_user&.can_admin_all_resources?

    true
  end
end

NotesFinder.prepend_mod_with('NotesFinder')
