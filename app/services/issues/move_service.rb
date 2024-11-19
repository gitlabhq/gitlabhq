# frozen_string_literal: true

module Issues
  class MoveService < Issuable::Clone::BaseService
    extend ::Gitlab::Utils::Override

    BATCH_SIZE = 100

    MoveError = Class.new(StandardError)

    def execute(issue, target_project, move_any_issue_type = false)
      @move_any_issue_type = move_any_issue_type
      @target_project = target_project

      verify_can_move_issue!(issue, target_project)

      super(issue, target_project)

      notify_participants

      # Updates old issue sent notifications allowing
      # to receive service desk emails on the new moved issue.
      update_service_desk_sent_notifications

      copy_email_participants
      queue_copy_designs
      copy_timelogs

      new_entity
    end

    private

    attr_reader :target_project, :move_any_issue_type

    override :after_clone_actions
    def after_clone_actions
      move_children
    end

    def move_children
      WorkItems::ParentLink.for_parents(original_entity).each do |link|
        new_child = self.class.new(
          container: container,
          current_user: current_user
        ).execute(
          ::Issue.find(link.work_item_id),
          target_project,
          true
        )

        WorkItems::ParentLink.create!(work_item_id: new_child.id, work_item_parent_id: new_entity.id)
      end
    end

    def verify_can_move_issue!(issue, target_project)
      unless issue.supports_move_and_clone? || move_any_issue_type
        raise MoveError, s_('MoveIssue|Cannot move issues of \'%{issue_type}\' type.') % { issue_type: issue.issue_type }
      end

      unless issue.can_move?(current_user, @target_project)
        raise MoveError, s_('MoveIssue|Cannot move issue due to insufficient permissions!')
      end

      if @project == @target_project
        raise MoveError, s_('MoveIssue|Cannot move issue to project it originates from!')
      end
    end

    def update_service_desk_sent_notifications
      context = { project_id: new_entity.project_id, noteable_id: new_entity.id }

      original_entity.run_after_commit_or_now do
        next unless from_service_desk?

        sent_notifications.update_all(**context)
      end
    end

    def copy_email_participants
      new_attributes = { id: nil, issue_id: new_entity.id }

      new_participants = original_entity.issue_email_participants.dup

      new_participants.each do |participant|
        participant.assign_attributes(new_attributes)
      end

      IssueEmailParticipant.bulk_insert!(new_participants)
    end

    override :update_old_entity
    def update_old_entity
      super

      recreate_related_issues
      mark_as_moved
    end

    override :update_new_entity
    def update_new_entity
      super

      copy_contacts
    end

    def create_new_entity
      new_params = {
        id: nil,
        iid: nil,
        relative_position: relative_position,
        project: target_project,
        author: original_entity.author,
        assignee_ids: original_entity.assignee_ids,
        moved_issue: true,
        imported_from: :none
      }

      new_params = original_entity.serializable_hash.symbolize_keys.merge(new_params)
      new_params = new_params.merge(rewritten_old_entity_attributes)
      # spam checking is not necessary, as no new content is being created.

      # Skip creation of system notes for existing attributes of the issue. The system notes of the old
      # issue are copied over so we don't want to end up with duplicate notes.
      create_result = CreateService.new(
        container: @target_project,
        current_user: @current_user,
        params: new_params,
        perform_spam_check: false
      ).execute(skip_system_notes: true)

      raise MoveError, create_result.errors.join(', ') if create_result.error? && create_result[:issue].blank?

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

    def copy_timelogs
      return if original_entity.timelogs.empty?

      WorkItems::CopyTimelogsWorker.perform_async(original_entity.id, new_entity.id)
    end

    def mark_as_moved
      original_entity.update(moved_to: new_entity)
    end

    def recreate_related_issues
      source_issue_links = IssueLink.for_source(original_entity)
      target_issue_links = IssueLink.for_target(original_entity)

      source_issue_links.each_batch(of: BATCH_SIZE) do |links_batch|
        new_links = new_links(links_batch, reference_attribute: 'source_id')
        ::IssueLink.insert_all!(new_links) if new_links.any?
      end

      target_issue_links.each_batch(of: BATCH_SIZE) do |links_batch|
        new_links = new_links(links_batch, reference_attribute: 'target_id')
        ::IssueLink.insert_all!(new_links) if new_links.any?
      end

      source_issue_links.each_batch(of: BATCH_SIZE) do |links_batch|
        links_batch.delete_all
      end

      target_issue_links.each_batch(of: BATCH_SIZE) do |links_batch|
        links_batch.delete_all
      end
    end

    def new_links(links_batch, reference_attribute:)
      links_batch.map do |link|
        link.attributes.except('id', 'namespace_id').merge(reference_attribute => new_entity.id)
      end
    end

    def copy_contacts
      return unless original_entity.project.root_ancestor == new_entity.project.root_ancestor

      new_entity.customer_relations_contacts = original_entity.customer_relations_contacts
    end

    def notify_participants
      context = { original: original_entity, new: new_entity, user: @current_user, service: notification_service }

      original_entity.run_after_commit_or_now do
        context[:service].async.issue_moved(context[:original], context[:new], context[:user])
      end
    end

    def add_note_from
      SystemNoteService.noteable_moved(
        new_entity,
        target_project,
        original_entity,
        current_user,
        direction: :from
      )
    end

    def add_note_to
      SystemNoteService.noteable_moved(
        original_entity,
        old_project,
        new_entity,
        current_user,
        direction: :to
      )
    end
  end
end

Issues::MoveService.prepend_mod_with('Issues::MoveService')
