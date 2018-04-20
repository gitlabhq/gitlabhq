module Issues
  class MoveService < Issues::BaseService
    prepend ::EE::Issues::MoveService

    MoveError = Class.new(StandardError)

    def execute(issue, new_project)
      @old_issue = issue
      @old_project = @project
      @new_project = new_project

      unless issue.can_move?(current_user, new_project)
        raise MoveError, 'Cannot move issue due to insufficient permissions!'
      end

      if @project == new_project
        raise MoveError, 'Cannot move issue to project it originates from!'
      end

      # Using transaction because of a high resources footprint
      # on rewriting notes (unfolding references)
      #
      ActiveRecord::Base.transaction do
        @new_issue = create_new_issue

        update_new_issue
        update_old_issue
      end

      notify_participants

      @new_issue
    end

    private

    def update_new_issue
      rewrite_notes
      rewrite_issue_award_emoji
      add_note_moved_from
    end

    def update_old_issue
      add_note_moved_to
      close_issue
      mark_as_moved
    end

    def create_new_issue
      new_params = { id: nil, iid: nil, label_ids: cloneable_label_ids,
                     milestone_id: cloneable_milestone_id,
                     project: @new_project, author: @old_issue.author,
                     description: rewrite_content(@old_issue.description),
                     assignee_ids: @old_issue.assignee_ids }

      new_params = @old_issue.serializable_hash.symbolize_keys.merge(new_params)
      CreateService.new(@new_project, @current_user, new_params).execute
    end

    def cloneable_label_ids
      params = {
        project_id: @new_project.id,
        title: @old_issue.labels.pluck(:title)
      }

      LabelsFinder.new(current_user, params).execute.pluck(:id)
    end

    def cloneable_milestone_id
      title = @old_issue.milestone&.title
      return unless title

      if @new_project.group && can?(current_user, :read_group, @new_project.group)
        group_id = @new_project.group.id
      end

      params =
        { title: title, project_ids: @new_project.id, group_ids: group_id }

      milestones = MilestonesFinder.new(params).execute
      milestones.first&.id
    end

    def rewrite_notes
      @old_issue.notes_with_associations.find_each do |note|
        new_note = note.dup
        new_params = { project: @new_project, noteable: @new_issue,
                       note: rewrite_content(new_note.note),
                       created_at: note.created_at,
                       updated_at: note.updated_at }

        new_note.update(new_params)

        rewrite_award_emoji(note, new_note)
      end
    end

    def rewrite_issue_award_emoji
      rewrite_award_emoji(@old_issue, @new_issue)
    end

    def rewrite_award_emoji(old_awardable, new_awardable)
      old_awardable.award_emoji.each do |award|
        new_award = award.dup
        new_award.awardable = new_awardable
        new_award.save
      end
    end

    def rewrite_content(content)
      return unless content

      rewriters = [Gitlab::Gfm::ReferenceRewriter,
                   Gitlab::Gfm::UploadsRewriter]

      rewriters.inject(content) do |text, klass|
        rewriter = klass.new(text, @old_project, @current_user)
        rewriter.rewrite(@new_project)
      end
    end

    def close_issue
      close_service = CloseService.new(@old_project, @current_user)
      close_service.execute(@old_issue, notifications: false, system_note: false)
    end

    def add_note_moved_from
      SystemNoteService.noteable_moved(@new_issue, @new_project,
                                       @old_issue, @current_user,
                                       direction: :from)
    end

    def add_note_moved_to
      SystemNoteService.noteable_moved(@old_issue, @old_project,
                                       @new_issue, @current_user,
                                       direction: :to)
    end

    def mark_as_moved
      @old_issue.update(moved_to: @new_issue)
    end

    def notify_participants
      notification_service.async.issue_moved(@old_issue, @new_issue, @current_user)
    end
  end
end
