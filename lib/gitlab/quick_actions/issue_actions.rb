# frozen_string_literal: true

module Gitlab
  module QuickActions
    module IssueActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # Issue only quick actions definition
        desc { _('Set due date') }
        explanation do |due_date|
          _("Sets the due date to %{due_date}.") % { due_date: due_date.strftime('%b %-d, %Y') } if due_date
        end
        execution_message do |due_date|
          _("Set the due date to %{due_date}.") % { due_date: due_date.strftime('%b %-d, %Y') } if due_date
        end
        params '<in 2 days | this Friday | December 31st>'
        types Issue
        condition do
          quick_action_target.respond_to?(:due_date) &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        parse_params do |due_date_param|
          Chronic.parse(due_date_param).try(:to_date)
        end
        command :due do |due_date|
          if due_date
            @updates[:due_date] = due_date
          else
            @execution_message[:due] = _('Failed to set due date because the date format is invalid.')
          end
        end

        desc { _('Remove due date') }
        explanation { _('Removes the due date.') }
        execution_message { _('Removed the due date.') }
        types Issue
        condition do
          quick_action_target.persisted? &&
            quick_action_target.respond_to?(:due_date) &&
            quick_action_target.due_date? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        command :remove_due_date do
          @updates[:due_date] = nil
        end

        desc { _('Move issue from one column of the board to another') }
        explanation do |target_list_name|
          label = find_label_references(target_list_name).first
          _("Moves issue to %{label} column in the board.") % { label: label } if label
        end
        params '~"Target column"'
        types Issue
        condition do
          current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target) &&
            quick_action_target.project.boards.count == 1
        end
        command :board_move do |target_list_name|
          labels = find_labels(target_list_name)
          label_ids = labels.map(&:id)

          if label_ids.size > 1
            message = _('Failed to move this issue because only a single label can be provided.')
          elsif !Label.on_project_board?(quick_action_target.project_id, label_ids.first)
            message = _('Failed to move this issue because label was not found.')
          else
            label_id = label_ids.first

            @updates[:remove_label_ids] =
              quick_action_target.labels.on_project_boards(quick_action_target.project_id).where.not(id: label_id).pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
            @updates[:add_label_ids] = [label_id]

            message = _("Moved issue to %{label} column in the board.") % { label: labels_to_reference(labels).first }
          end

          @execution_message[:board_move] = message
        end

        desc { _('Mark this issue as a duplicate of another issue') }
        explanation do |canonical_item|
          _, message = mark_as_duplicate(canonical_item, for_explain: true)

          message
        end
        params '<#item | group/project#item | item URL>'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"set_#{quick_action_target.to_ability_name}_metadata", quick_action_target)
        end
        parse_params do |duplicate_param|
          extract_references(duplicate_param, :issue).first ||
            extract_references(duplicate_param, :work_item).first ||
            extract_references(duplicate_param, :epic).first&.sync_object
        end
        command :duplicate do |canonical_item|
          can_duplicate_flag, message = mark_as_duplicate(canonical_item)
          @updates[:canonical_issue_id] = canonical_item.id if can_duplicate_flag
          @execution_message[:duplicate] = message
        end

        desc { _('Clone this issue') }
        explanation do |project = quick_action_target.project.full_path|
          _("Clones this issue, without comments, to %{project}.") % { project: project }
        end
        params 'path/to/project [--with_notes]'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"clone_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :clone do |params = ''|
          params = params.split(' ')
          with_notes = params.delete('--with_notes').present?

          # If we have more than 1 param, then the user supplied too many spaces, or mistyped `--with_notes`
          if params.size > 1
            @execution_message[:clone] = _('Failed to clone this issue: wrong parameters.')
            next
          end

          target_project_path = params[0]
          target_project = target_project_path.present? ? Project.find_by_full_path(target_project_path) : quick_action_target.project

          if target_project.present?
            @updates[:target_clone_project] = target_project
            @updates[:clone_with_notes] = with_notes

            message = _("Cloned this issue to %{path_to_project}.") % { path_to_project: target_project_path || quick_action_target.project.full_path }
          else
            message = _("Failed to clone this issue because target project doesn't exist.")
          end

          @execution_message[:clone] = message
        end

        desc { _('Move this issue to another project') }
        explanation do |path_to_project|
          _("Moves this issue to %{path_to_project}.") % { path_to_project: path_to_project }
        end
        params 'path/to/project'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"move_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :move do |target_project_path|
          target_project = Project.find_by_full_path(target_project_path)

          if target_project.present?
            @updates[:target_project] = target_project

            message = _("Moved this issue to %{path_to_project}.") % { path_to_project: target_project_path }
          else
            message = _("Failed to move this issue because target project doesn't exist.")
          end

          @execution_message[:move] = message
        end

        desc { _('Create a merge request') }
        explanation do |branch_name = nil|
          if branch_name
            _("Creates branch '%{branch_name}' and a merge request to resolve this issue.") % { branch_name: branch_name }
          else
            _('Creates a branch and a merge request to resolve this issue.')
          end
        end
        execution_message do |branch_name = nil|
          if branch_name
            _("Created branch '%{branch_name}' and a merge request to resolve this issue.") % { branch_name: branch_name }
          else
            _('Created a branch and a merge request to resolve this issue.')
          end
        end
        params "<branch name>"
        types Issue
        condition do
          current_user.can?(:create_merge_request_in, project) && current_user.can?(:push_code, project)
        end
        command :create_merge_request do |branch_name = nil|
          @updates[:create_merge_request] = {
            branch_name: branch_name,
            issue_iid: quick_action_target.iid
          }
        end

        desc { _('Add Zoom meeting') }
        explanation { _('Adds a Zoom meeting.') }
        params do
          zoom_link_params
        end
        types Issue
        condition do
          @zoom_service = zoom_link_service

          @zoom_service.can_add_link?
        end
        parse_params do |link_params|
          @zoom_service.parse_link(link_params)
        end
        command :zoom do |link, link_text = nil|
          result = add_zoom_link(link, link_text)
          @execution_message[:zoom] = result.message
          merge_updates(result, @updates)
        end

        desc { _('Remove Zoom meeting') }
        explanation { _('Remove Zoom meeting.') }
        execution_message { _('Zoom meeting removed') }
        types Issue
        condition do
          @zoom_service = zoom_link_service
          @zoom_service.can_remove_link?
        end
        command :remove_zoom do
          result = @zoom_service.remove_link
          @execution_message[:remove_zoom] = result.message
        end

        desc { _("Add email participants that don't have a GitLab account.") }
        explanation { _("Adds email participants that don't have a GitLab account.") }
        params 'email1@example.com email2@example.com (up to 6 emails)'
        types Issue
        condition do
          quick_action_target.persisted? &&
            Feature.enabled?(:issue_email_participants, parent) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target) &&
            issue_or_work_item_feature_flag_enabled?
        end
        command :add_email do |emails = ""|
          response = ::IssueEmailParticipants::CreateService.new(
            target: quick_action_target,
            current_user: current_user,
            emails: emails.split(' ')
          ).execute

          @execution_message[:add_email] = response.message
        end

        desc { _('Remove email participants') }
        explanation { _('Removes email participants.') }
        params 'email1@example.com email2@example.com (up to 6 emails)'
        types Issue
        condition do
          quick_action_target.persisted? &&
            Feature.enabled?(:issue_email_participants, parent) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target) &&
            quick_action_target.issue_email_participants.any?
        end
        command :remove_email do |emails = ""|
          response = ::IssueEmailParticipants::DestroyService.new(
            target: quick_action_target,
            current_user: current_user,
            emails: emails.split(' ')
          ).execute

          @execution_message[:remove_email] = response.message
        end

        desc { s_('ServiceDesk|Convert issue to Service Desk ticket') }
        explanation { s_('ServiceDesk|Converts this issue to a Service Desk ticket.') }
        params 'external-issue-author@example.com'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target) &&
            quick_action_target.respond_to?(:from_service_desk?) &&
            !quick_action_target.from_service_desk?
        end
        command :convert_to_ticket do |email = ""|
          response = ::Issues::ConvertToTicketService.new(
            target: quick_action_target,
            current_user: current_user,
            email: email
          ).execute

          @execution_message[:convert_to_ticket] = response.message
        end

        desc { _('Promote issue to incident') }
        explanation { _('Promotes issue to incident') }
        execution_message { _('Issue has been promoted to incident') }
        types Issue
        condition do
          !quick_action_target.work_item_type&.incident? &&
            current_user.can?(:"set_#{quick_action_target.issue_type}_metadata", quick_action_target)
        end
        command :promote_to_incident do
          @updates[:work_item_type] = ::WorkItems::Type.default_by_type(:incident)
        end

        desc { _('Add customer relation contacts') }
        explanation { _('Add customer relation contacts.') }
        params '[contact:contact@example.com] [contact:person@example.org]'
        types Issue
        condition do
          current_user.can?(:set_issue_crm_contacts, quick_action_target) &&
            CustomerRelations::Contact.exists_for_group?(quick_action_target.resource_parent.crm_group)
        end
        execution_message do
          _('One or more contacts were successfully added.')
        end
        command :add_contacts do |contact_emails|
          @updates[:add_contacts] ||= []
          @updates[:add_contacts] += contact_emails.split(' ')
        end

        desc { _('Remove customer relation contacts') }
        explanation { _('Remove customer relation contacts.') }
        params '[contact:contact@example.com] [contact:person@example.org]'
        types Issue
        condition do
          current_user.can?(:set_issue_crm_contacts, quick_action_target) &&
            quick_action_target.customer_relations_contacts.exists?
        end
        execution_message do
          _('One or more contacts were successfully removed.')
        end
        command :remove_contacts do |contact_emails|
          @updates[:remove_contacts] ||= []
          @updates[:remove_contacts] += contact_emails.split(' ')
        end

        desc { _('Add a timeline event to incident') }
        explanation { _('Adds a timeline event to incident.') }
        params '<timeline comment> | <date(YYYY-MM-DD)> <time(HH:MM)>'
        types Issue
        condition do
          quick_action_target.work_item_type&.incident? &&
            current_user.can?(:admin_incident_management_timeline_event, quick_action_target)
        end
        parse_params do |event_params|
          Gitlab::QuickActions::TimelineTextAndDateTimeSeparator.new(event_params).execute
        end
        command :timeline do |event_text, date_time|
          if event_text && date_time
            timeline_event = timeline_event_create_service(event_text, date_time).execute

            @execution_message[:timeline] =
              if timeline_event.success?
                _('Timeline event added successfully.')
              else
                _('Something went wrong while adding timeline event.')
              end
          end
        end
      end

      private

      def mark_as_duplicate(canonical_item, for_explain: false)
        return [false, item_not_found_message(for_explain)] if canonical_item.blank?
        return [false, same_item_message(for_explain)] if canonical_item.id == quick_action_target.id
        return [false, insufficient_permission_message(for_explain)] unless can_mark_as_duplicate?(canonical_item)

        [true, mark_as_duplicate_message(canonical_item, for_explain)]
      end

      def mark_as_duplicate_message(canonical_item, for_explain)
        canonical_item_url = Gitlab::UrlBuilder.build(canonical_item)
        if for_explain
          _("Closes this %{work_item_type}. Marks as related to, and a duplicate of, %{duplicate_param}.") % {
            work_item_type: quick_action_target.work_item_type.name, duplicate_param: canonical_item_url
          }
        else
          _("Closed this %{work_item_type}. Marked as related to, and a duplicate of, %{duplicate_param}.") % {
            work_item_type: quick_action_target.work_item_type.name, duplicate_param: canonical_item_url
          }
        end
      end

      def can_mark_as_duplicate?(canonical_item)
        current_user.can?("update_#{quick_action_target.to_ability_name}", quick_action_target) &&
          current_user.can?(:create_note, canonical_item)
      end

      def insufficient_permission_message(for_explain)
        if for_explain
          _('Cannot mark this %{work_item_type} as duplicate due to insufficient permissions.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        else
          _('Failed to mark this %{work_item_type} as duplicate due to insufficient permissions.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        end
      end

      def same_item_message(for_explain)
        if for_explain
          _('Cannot mark the %{work_item_type} as duplicate of itself.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        else
          _('Failed to mark the %{work_item_type} as duplicate of itself.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        end
      end

      def item_not_found_message(for_explain)
        if for_explain
          _('Cannot mark this %{work_item_type} as a duplicate because referenced item was not found.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        else
          _('Failed to mark this %{work_item_type} as a duplicate because referenced item was not found.') % {
            work_item_type: quick_action_target.work_item_type.name
          }
        end
      end

      def zoom_link_service
        ::Issues::ZoomLinkService.new(container: quick_action_target.project, current_user: current_user, params: { issue: quick_action_target })
      end

      def zoom_link_params
        '<Zoom URL>'
      end

      def add_zoom_link(link, _link_text)
        zoom_link_service.add_link(link)
      end

      def merge_updates(result, update_hash)
        update_hash.merge!(result.payload) if result.payload
      end

      def timeline_event_create_service(event_text, event_date_time)
        ::IncidentManagement::TimelineEvents::CreateService.new(quick_action_target, current_user, { note: event_text, occurred_at: event_date_time, editable: true })
      end

      def issue_or_work_item_feature_flag_enabled?
        !quick_action_target.is_a?(WorkItem) ||
          (
            quick_action_target.resource_parent.is_a?(Project) &&
            quick_action_target.resource_parent.work_items_alpha_feature_flag_enabled?
          )
      end
    end
  end
end
