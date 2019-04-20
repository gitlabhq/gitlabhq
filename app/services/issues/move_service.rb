# frozen_string_literal: true

module Issues
  class MoveService < Issuable::Clone::BaseService
    MoveError = Class.new(StandardError)

    def execute(issue, target_project)
      @target_project = target_project

      unless issue.can_move?(current_user, @target_project)
        raise MoveError, s_('MoveIssue|Cannot move issue due to insufficient permissions!')
      end

      if @project == @target_project
        raise MoveError, s_('MoveIssue|Cannot move issue to project it originates from!')
      end

      super

      notify_participants

      new_entity
    end

    private

    def update_old_entity
      super

      mark_as_moved
    end

    def create_new_entity
      new_params = {
                     id: nil,
                     iid: nil,
                     project: @target_project,
                     author: original_entity.author,
                     assignee_ids: original_entity.assignee_ids
                   }

      new_params = original_entity.serializable_hash.symbolize_keys.merge(new_params)
      CreateService.new(@target_project, @current_user, new_params).execute
    end

    def mark_as_moved
      original_entity.update(moved_to: new_entity)
    end

    def notify_participants
      notification_service.async.issue_moved(original_entity, new_entity, @current_user)
    end

    def add_note_from
      SystemNoteService.noteable_moved(new_entity, @target_project,
                                       original_entity, current_user,
                                       direction: :from)
    end

    def add_note_to
      SystemNoteService.noteable_moved(original_entity, old_project,
                                       new_entity, current_user,
                                       direction: :to)
    end
  end
end
