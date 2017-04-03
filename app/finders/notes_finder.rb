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
    init_collection
  end

  def execute
    @notes = since_fetch_at(@params[:last_fetched_at]) if @params[:last_fetched_at]
    @notes
  end

  private

  def init_collection
    @notes =
      if @params[:target_id]
        on_target(@params[:target_type], @params[:target_id])
      else
        notes_of_any_type
      end
  end

  def notes_of_any_type
    types = %w(commit issue merge_request snippet)
    note_relations = types.map { |t| notes_for_type(t) }
    note_relations.map!{ |notes| search(@params[:search], notes) } if @params[:search]
    UnionFinder.new.find_union(note_relations, Note)
  end

  def noteables_for_type(noteable_type)
    case noteable_type
    when "issue"
      IssuesFinder.new(@current_user, project_id: @project.id).execute
    when "merge_request"
      MergeRequestsFinder.new(@current_user, project_id: @project.id).execute
    when "snippet", "project_snippet"
      SnippetsFinder.new.execute(@current_user, filter: :by_project, project: @project)
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

  def on_target(target_type, target_id)
    if target_type == "commit"
      notes_for_type('commit').for_commit_id(target_id)
    else
      target = noteables_for_type(target_type).find(target_id)

      if target.respond_to?(:related_notes)
        target.related_notes
      else
        target.notes
      end
    end
  end

  # Searches for notes matching the given query.
  #
  # This method uses ILIKE on PostgreSQL and LIKE on MySQL.
  #
  def search(query, notes_relation = @notes)
    pattern = "%#{query}%"
    notes_relation.where(Note.arel_table[:note].matches(pattern))
  end

  # Notes changed since last fetch
  # Uses overlapping intervals to avoid worrying about race conditions
  def since_fetch_at(fetch_time)
    # Default to 0 to remain compatible with old clients
    last_fetched_at = Time.at(@params.fetch(:last_fetched_at, 0).to_i)

    @notes.where('updated_at > ?', last_fetched_at - FETCH_OVERLAP).fresh
  end
end
