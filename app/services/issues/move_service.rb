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

      # Updates old issue sent notifications allowing
      # to receive service desk emails on the new moved issue.
      update_service_desk_sent_notifications

      queue_copy_designs

      new_entity
    end

    private

    attr_reader :target_project

    def update_service_desk_sent_notifications
      return unless original_entity.from_service_desk?

      original_entity
        .sent_notifications.update_all(project_id: new_entity.project_id, noteable_id: new_entity.id)
    end

    def update_old_entity
      super

      rewrite_related_issues
      mark_as_moved
    end

    def create_new_entity
      new_params = {
        id: nil,
        iid: nil,
        relative_position: relative_position,
        project: target_project,
        author: original_entity.author,
        assignee_ids: original_entity.assignee_ids,
        moved_issue: true
      }

      new_params = original_entity.serializable_hash.symbolize_keys.merge(new_params)
      # spam checking is not necessary, as no new content is being created. Passing nil for
      # spam_params will cause SpamActionService to skip checking and return a success response.
      spam_params = nil

      # Skip creation of system notes for existing attributes of the issue. The system notes of the old
      # issue are copied over so we don't want to end up with duplicate notes.
      CreateService.new(project: @target_project, current_user: @current_user, params: new_params, spam_params: spam_params).execute(skip_system_notes: true)
    end

    def queue_copy_designs
      return unless original_entity.designs.present?

      response = DesignManagement::CopyDesignCollection::QueueService.new(
        current_user,
        original_entity,
        new_entity
      ).execute

      log_error(response.message) if response.error?
    end

    def mark_as_moved
      original_entity.update(moved_to: new_entity)
    end

    def rewrite_related_issues
      source_issue_links = IssueLink.for_source_issue(original_entity)
      source_issue_links.update_all(source_id: new_entity.id)

      target_issue_links = IssueLink.for_target_issue(original_entity)
      target_issue_links.update_all(target_id: new_entity.id)
    end

    def notify_participants
      notification_service.async.issue_moved(original_entity, new_entity, @current_user)
    end

    def add_note_from
      SystemNoteService.noteable_moved(new_entity, target_project,
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

Issues::MoveService.prepend_mod_with('Issues::MoveService')
