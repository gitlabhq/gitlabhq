class NotesFinder
  FETCH_OVERLAP = 5.seconds

  # Used to filter Notes
  # When used with target_type and target_id this returns notes specifically for the controller
  #
  # Arguments:
  #   current_user - which user check authorizations with
  #   project - which project to look for notes on
  #   params:
  #     target_type: string
  #     target_id: integer
  #     last_fetched_at: time
  #     search: string
  #
  def initialize(project, current_user, params = {})
    @project = project
    @current_user = current_user
    @params = params
  end

  def execute
    notes = init_collection
    notes = since_fetch_at(notes)
    notes.fresh
  end

  def target
    return @target if defined?(@target)

    target_type = @params[:target_type]
    target_id   = @params[:target_id]

    return @target = nil unless target_type && target_id

    @target =
      if target_type == "commit"
        if Ability.allowed?(@current_user, :download_code, @project)
          @project.commit(target_id)
        end
      else
        noteables_for_type(target_type).find(target_id)
      end
  end

  private

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

  def target_type
    @params[:target_type]
  end

  def notes_of_any_type
    types = %w(commit issue merge_request snippet)
    note_relations = types.map { |t| notes_for_type(t) }
    note_relations.map! { |notes| search(notes) }
    UnionFinder.new.find_union(note_relations, Note.includes(:author))
  end

  def noteables_for_type(noteable_type)
    case noteable_type
    when "issue"
      IssuesFinder.new(@current_user, project_id: @project.id).execute
    when "merge_request"
      MergeRequestsFinder.new(@current_user, project_id: @project.id).execute
    when "snippet", "project_snippet"
      SnippetsFinder.new(@current_user, project: @project).execute
    when "personal_snippet"
      PersonalSnippet.all
    else
      raise 'invalid target_type'
    end
  end

  def notes_for_type(noteable_type)
    if noteable_type == "commit"
      if Ability.allowed?(@current_user, :download_code, @project)
        @project.notes.where(noteable_type: 'Commit')
      else
        Note.none
      end
    else
      finder = noteables_for_type(noteable_type)
      @project.notes.where(noteable_type: finder.base_class.name, noteable_id: finder.reorder(nil))
    end
  end

  def notes_on_target
    if target.respond_to?(:related_notes)
      target.related_notes
    else
      target.notes
    end
  end

  # Searches for notes matching the given query.
  #
  # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
  #
  def search(notes)
    query = @params[:search]
    return notes unless query

    notes.search(query)
  end

  # Notes changed since last fetch
  # Uses overlapping intervals to avoid worrying about race conditions
  def since_fetch_at(notes)
    return notes unless @params[:last_fetched_at]

    # Default to 0 to remain compatible with old clients
    last_fetched_at = Time.at(@params.fetch(:last_fetched_at, 0).to_i)
    notes.updated_after(last_fetched_at - FETCH_OVERLAP)
  end
end
