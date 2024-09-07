# frozen_string_literal: true

module Issues
  class CloneService < Issuable::Clone::BaseService
    CloneError = Class.new(StandardError)

    def execute(issue, target_project, with_notes: false)
      @target_project = target_project
      @with_notes = with_notes

      verify_can_clone_issue!(issue, target_project)

      super(issue, target_project)

      notify_participants

      queue_copy_designs

      new_entity
    end

    private

    attr_reader :target_project
    attr_reader :with_notes

    def verify_can_clone_issue!(issue, target_project)
      unless issue.supports_move_and_clone?
        raise CloneError, s_('CloneIssue|Cannot clone issues of \'%{issue_type}\' type.') % { issue_type: issue.issue_type }
      end

      unless issue.can_clone?(current_user, target_project)
        raise CloneError, s_('CloneIssue|Cannot clone issue due to insufficient permissions!')
      end

      if target_project.pending_delete?
        raise CloneError, s_('CloneIssue|Cannot clone issue to target project as it is pending deletion.')
      end
    end

    def update_new_entity
      # we don't call `super` because we want to be able to decide whether or not to copy all comments over.
      update_new_entity_description

      if with_notes
        copy_notes
        copy_resource_events
      end
    end

    def update_old_entity
      # no-op
      # The base_service closes the old issue, we don't want that, so we override here so nothing happens.
    end

    def create_new_entity
      new_params = {
        id: nil,
        iid: nil,
        relative_position: relative_position,
        project: target_project,
        author: current_user,
        assignee_ids: original_entity.assignee_ids
      }

      new_params = original_entity.serializable_hash.symbolize_keys.except(:project_id, :author_id).merge(new_params)
      new_params = new_params.merge(rewritten_old_entity_attributes)
      new_params.delete(:imported_from)
      new_params.delete(:created_at)
      new_params.delete(:updated_at)

      # spam checking is not necessary, as no new content is being created.

      # Skip creation of system notes for existing attributes of the issue when cloning with notes.
      # The system notes of the old issue are copied over so we don't want to end up with duplicate notes.
      # When cloning without notes, we want to generate system notes for the attributes that were copied.
      create_result = CreateService.new(
        container: target_project,
        current_user: current_user,
        params: new_params,
        perform_spam_check: false
      ).execute(skip_system_notes: with_notes)

      raise CloneError, create_result.errors.join(', ') if create_result.error? && create_result[:issue].blank?

      create_result[:issue]
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

    def notify_participants
      notification_service.async.issue_cloned(original_entity, new_entity, current_user)
    end

    def add_note_from
      SystemNoteService.noteable_cloned(
        new_entity,
        target_project,
        original_entity,
        current_user,
        direction: :from,
        created_at: new_entity.created_at
      )
    end

    def add_note_to
      SystemNoteService.noteable_cloned(original_entity, old_project,
        new_entity, current_user,
        direction: :to)
    end
  end
end

Issues::CloneService.prepend_mod_with('Issues::CloneService')
