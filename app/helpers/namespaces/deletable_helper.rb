# frozen_string_literal: true

module Namespaces
  module DeletableHelper
    include NamespaceHelper

    def permanent_deletion_date_formatted(container_or_date = Date.current, format: '%F')
      date =
        if container_or_date.respond_to?(:self_deletion_scheduled_deletion_created_on)
          container_or_date.self_deletion_scheduled_deletion_created_on
        else
          container_or_date
        end

      return unless date.is_a?(Date) || date.is_a?(Time)

      ::Gitlab::CurrentSettings.deletion_adjourned_period.days.since(date).strftime(format)
    end

    def deletion_in_progress_or_scheduled_in_hierarchy_chain?(namespace)
      return false unless namespace.respond_to?(:deletion_in_progress_or_scheduled_in_hierarchy_chain?)

      namespace.deletion_in_progress_or_scheduled_in_hierarchy_chain?
    end

    def self_or_ancestors_deletion_in_progress_or_scheduled_message(namespace)
      _self_deletion_in_progress_message(namespace) || _deletion_scheduled_in_hierarchy_chain_message(namespace)
    end

    def _self_deletion_in_progress_message(namespace)
      return unless namespace.self_deletion_in_progress?

      messages = {
        group: _('This group and its subgroups are being deleted.'),
        project: _('This project is being deleted. Repository and other project resources are read-only.')
      }

      message_for_namespace(namespace, messages)
    end

    def _deletion_scheduled_in_hierarchy_chain_message(namespace)
      if namespace.self_deletion_scheduled?
        _self_deletion_scheduled_message(namespace)
      else
        _parent_deletion_scheduled_message(namespace)
      end
    end

    def _self_deletion_scheduled_message(namespace)
      date = permanent_deletion_date_formatted(namespace)

      messages = {
        group: _('This group and its subgroups and projects are pending deletion, and will be deleted on %{date}.'),
        project: _('This project is pending deletion, and will be deleted on %{date}. Repository and other project ' \
          'resources are read-only.')
      }

      safe_format(
        message_for_namespace(namespace, messages),
        date: tag.strong(date)
      )
    end

    def _parent_deletion_scheduled_message(namespace)
      namespace_pending_deletion = namespace.first_scheduled_for_deletion_in_hierarchy_chain
      date = permanent_deletion_date_formatted(namespace_pending_deletion)

      messages = {
        group: _('This group will be deleted on %{date} because its parent group is ' \
          'scheduled for deletion.'),
        project: _('This project will be deleted on %{date} because its parent group is ' \
          'scheduled for deletion.')
      }

      safe_format(
        message_for_namespace(namespace, messages),
        date: tag.strong(date)
      )
    end

    def delete_delayed_namespace_message(namespace)
      messages = {
        group: _('This action will place this group, including its subgroups and projects, ' \
          'in a pending deletion state for %{deletion_adjourned_period} days, ' \
          'and delete it permanently on %{date}.'),
        project: _('This action will place this project, including all its resources, ' \
          'in a pending deletion state for %{deletion_adjourned_period} days, ' \
          'and delete it permanently on %{date}.')
      }

      safe_format(
        message_for_namespace(namespace, messages),
        deletion_adjourned_period: namespace.deletion_adjourned_period,
        date: tag.strong(permanent_deletion_date_formatted)
      )
    end

    def delete_immediately_namespace_scheduled_for_deletion_message(namespace)
      messages = {
        group: _('This group is scheduled for deletion on %{date}. ' \
          'This action will permanently delete this group, ' \
          'including its subgroups and projects, %{strongOpen}immediately%{strongClose}. ' \
          'This action cannot be undone.'),
        project: _('This project is scheduled for deletion on %{date}. ' \
          'This action will permanently delete this project, ' \
          'including all its resources, %{strongOpen}immediately%{strongClose}. ' \
          'This action cannot be undone.')
      }

      safe_format(
        message_for_namespace(namespace, messages),
        date: tag.strong(permanent_deletion_date_formatted(namespace)),
        strongOpen: '<strong>'.html_safe,
        strongClose: '</strong>'.html_safe
      )
    end

    def group_confirm_modal_data(
      group:,
      remove_form_id: nil,
      permanently_remove: false,
      button_text: nil,
      has_security_policy_project: false)
      {
        remove_form_id: remove_form_id,
        button_text: button_text.nil? ? _('Delete') : button_text,
        button_testid: 'remove-group-button',
        disabled: (group.linked_to_subscription? || has_security_policy_project).to_s,
        confirm_danger_message: confirm_remove_group_message(group, permanently_remove),
        phrase: group.full_path,
        html_confirmation_message: 'true'
      }
    end

    def confirm_remove_group_message(group, permanently_remove)
      return _permanently_delete_group_message(group) if permanently_remove || group.self_deletion_scheduled?

      safe_format(
        _("The contents of this group, its subgroups and projects will be permanently deleted after " \
          "%{deletion_adjourned_period} days on %{date}. After this point, your data cannot be recovered."),
        deletion_adjourned_period: group.deletion_adjourned_period,
        date: tag.strong(permanent_deletion_date_formatted)
      )
    end

    def project_delete_delayed_button_data(project)
      _project_delete_button_shared_data(project).merge({
        form_path: project_path(project)
      })
    end

    def project_delete_immediately_button_data(project)
      _project_delete_button_shared_data(project, s_('ProjectSettings|Delete immediately')).merge({
        form_path: project_path(project, permanently_delete: true)
      })
    end

    def restore_namespace_title(namespace)
      messages = {
        group: _('Restore group'),
        project: _('Restore project')
      }

      message_for_namespace(namespace, messages)
    end

    def restore_namespace_path(namespace)
      paths = {
        group: ->(namespace) { group_restore_path(namespace) },
        project: ->(namespace) { namespace_project_restore_path(namespace.parent, namespace) }
      }

      message_for_namespace(namespace, paths)[namespace]
    end

    def restore_namespace_scheduled_for_deletion_message(namespace)
      messages = {
        group: _("This group has been scheduled for deletion on %{date}. " \
          "To cancel the scheduled deletion, you can restore this group, including all its resources."),
        project: _("This project has been scheduled for deletion on %{date}. " \
          "To cancel the scheduled deletion, you can restore this project, including all its resources.")
      }

      safe_format(
        message_for_namespace(namespace, messages),
        date: tag.strong(permanent_deletion_date_formatted(namespace))
      )
    end

    def _permanently_delete_group_message(group)
      content = ''.html_safe
      content << content_tag(:span,
        format(_("You are about to delete the group %{group_name}."), group_name: group.name))
      content << _additional_removed_items(group)
      content << _remove_group_warning
    end

    def _additional_removed_items(group)
      relations = {
        ->(count) { n_('%{count} subgroup', '%{count} subgroups', count) } => group.children,
        ->(count) {
          n_('%{count} active project', '%{count} active projects', count)
        } => group.all_projects.non_archived,
        ->(count) {
          n_('%{count} archived project', '%{count} archived projects', count)
        } => group.all_projects.archived
      }

      counts = relations.filter_map do |i18n_proc, relation|
        count = limited_counter_with_delimiter(relation, limit: 100, include_zero: false)
        next unless count

        content_tag(:li, format(i18n_proc[count.to_i], count: count))
      end

      if counts.any?
        safe_join([
          content_tag(:span, _(" This action will also delete:")),
          content_tag(:ul, safe_join(counts))
        ])
      else
        ''
      end
    end

    def _remove_group_warning
      content_tag(:p, class: 'gl-mb-0') do
        safe_format(
          _('After you delete a group, you %{strongOpen}cannot%{strongClose} restore it or its components.'),
          strongOpen: '<strong>'.html_safe,
          strongClose: '</strong>'.html_safe
        )
      end
    end

    def _project_delete_button_shared_data(project, button_text = nil)
      merge_requests_count = ::Projects::AllMergeRequestsCountService.new(project).count
      issues_count = ::Projects::AllIssuesCountService.new(project).count
      forks_count = ::Projects::ForksCountService.new(project).count

      {
        confirm_phrase: delete_confirm_phrase(project),
        name_with_namespace: project.name_with_namespace,
        is_fork: project.forked? ? 'true' : 'false',
        issues_count: number_with_delimiter(issues_count),
        merge_requests_count: number_with_delimiter(merge_requests_count),
        forks_count: number_with_delimiter(forks_count),
        stars_count: number_with_delimiter(project.star_count),
        button_text: button_text.presence || _('Delete'),
        permanent_deletion_date: permanent_deletion_date_formatted,
        marked_for_deletion: project.scheduled_for_deletion_in_hierarchy_chain?.to_s
      }
    end
  end
end
