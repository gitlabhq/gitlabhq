# frozen_string_literal: true

module Gitlab
  module QuickActions
    module IssueActions
      extend ActiveSupport::Concern
      include Gitlab::QuickActions::Dsl

      included do
        # Issue only quick actions definition
        desc _('Set due date')
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
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
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

        desc _('Remove due date')
        explanation _('Removes the due date.')
        execution_message _('Removed the due date.')
        types Issue
        condition do
          quick_action_target.persisted? &&
            quick_action_target.respond_to?(:due_date) &&
            quick_action_target.due_date? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
        end
        command :remove_due_date do
          @updates[:due_date] = nil
        end

        desc _('Move issue from one column of the board to another')
        explanation do |target_list_name|
          label = find_label_references(target_list_name).first
          _("Moves issue to %{label} column in the board.") % { label: label } if label
        end
        params '~"Target column"'
        types Issue
        condition do
          current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target) &&
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

        desc _('Mark this issue as a duplicate of another issue')
        explanation do |duplicate_reference|
          _("Marks this issue as a duplicate of %{duplicate_reference}.") % { duplicate_reference: duplicate_reference }
        end
        params '#issue'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"update_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :duplicate do |duplicate_param|
          canonical_issue = extract_references(duplicate_param, :issue).first

          if canonical_issue.present?
            @updates[:canonical_issue_id] = canonical_issue.id

            message = _("Marked this issue as a duplicate of %{duplicate_param}.") % { duplicate_param: duplicate_param }
          else
            message = _('Failed to mark this issue as a duplicate because referenced issue was not found.')
          end

          @execution_message[:duplicate] = message
        end

        desc _('Clone this issue')
        explanation do |project = quick_action_target.project.full_path|
          _("Clones this issue, without comments, to %{project}.") % { project: project }
        end
        params 'path/to/project [--with_notes]'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
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

        desc _('Move this issue to another project.')
        explanation do |path_to_project|
          _("Moves this issue to %{path_to_project}.") % { path_to_project: path_to_project }
        end
        params 'path/to/project'
        types Issue
        condition do
          quick_action_target.persisted? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", project)
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

        desc _('Make issue confidential')
        explanation do
          _('Makes this issue confidential.')
        end
        execution_message do
          _('Made this issue confidential.')
        end
        types Issue
        condition do
          quick_action_target.issue_type_supports?(:confidentiality) &&
            !quick_action_target.confidential? &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :confidential do
          @updates[:confidential] = true
        end

        desc _('Create a merge request')
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

        desc _('Add Zoom meeting')
        explanation _('Adds a Zoom meeting')
        params '<Zoom URL>'
        types Issue
        condition do
          @zoom_service = zoom_link_service
          @zoom_service.can_add_link?
        end
        parse_params do |link|
          @zoom_service.parse_link(link)
        end
        command :zoom do |link|
          result = @zoom_service.add_link(link)
          @execution_message[:zoom] = result.message
          @updates.merge!(result.payload) if result.payload
        end

        desc _('Remove Zoom meeting')
        explanation _('Remove Zoom meeting')
        execution_message _('Zoom meeting removed')
        types Issue
        condition do
          @zoom_service = zoom_link_service
          @zoom_service.can_remove_link?
        end
        command :remove_zoom do
          result = @zoom_service.remove_link
          @execution_message[:remove_zoom] = result.message
        end

        desc _('Add email participant(s)')
        explanation _('Adds email participant(s)')
        params 'email1@example.com email2@example.com (up to 6 emails)'
        types Issue
        condition do
          Feature.enabled?(:issue_email_participants, parent) &&
            current_user.can?(:"admin_#{quick_action_target.to_ability_name}", quick_action_target)
        end
        command :invite_email do |emails = ""|
          MAX_NUMBER_OF_EMAILS = 6

          existing_emails = quick_action_target.email_participants_emails_downcase
          emails_to_add = emails.split(' ').index_by { |email| [email.downcase, email] }.except(*existing_emails).each_value.first(MAX_NUMBER_OF_EMAILS)
          added_emails = []

          emails_to_add.each do |email|
            new_participant = quick_action_target.issue_email_participants.create(email: email)
            added_emails << email if new_participant.persisted?
          end

          if added_emails.any?
            message = _("added %{emails}") % { emails: added_emails.to_sentence }
            SystemNoteService.add_email_participants(quick_action_target, quick_action_target.project, current_user, message)
            @execution_message[:invite_email] = message.upcase_first << "."
          else
            @execution_message[:invite_email] = _("No email participants were added. Either none were provided, or they already exist.")
          end
        end

        private

        def zoom_link_service
          Issues::ZoomLinkService.new(project: quick_action_target.project, current_user: current_user, params: { issue: quick_action_target })
        end
      end
    end
  end
end
