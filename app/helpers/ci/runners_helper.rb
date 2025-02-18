# frozen_string_literal: true

module Ci
  module RunnersHelper
    include IconsHelper

    def runner_status_icon(runner, size: 16, icon_class: '')
      status = runner.status
      contacted_at = runner.contacted_at

      title = ''
      icon = 'warning-solid'
      span_class = ''

      case status
      when :online
        title = s_("Runners|Runner is online; last contact was %{runner_contact} ago") % { runner_contact: time_ago_in_words(contacted_at) }
        icon = 'status-active'
        span_class = 'gl-text-success'
      when :never_contacted
        title = s_("Runners|Runner has never contacted this instance")
        icon = 'warning-solid'
      when :offline
        title =
          if contacted_at
            s_("Runners|Runner is offline; last contact was %{runner_contact} ago") % { runner_contact: time_ago_in_words(contacted_at) }
          else
            s_("Runners|Runner is offline; it has never contacted this instance")
          end

        icon = 'status-waiting'
        span_class = 'gl-text-subtle'
      when :stale
        # runner may have contacted (or not) and be stale: consider both cases.
        title = contacted_at ? s_("Runners|Runner is stale; last contact was %{runner_contact} ago") % { runner_contact: time_ago_in_words(contacted_at) } : s_("Runners|Runner is stale; it has never contacted this instance")
        icon = 'time-out'
        span_class = 'gl-text-warning'
      end

      content_tag(:span, class: span_class, title: title, data: { toggle: 'tooltip', container: 'body', testid: 'runner-status-icon', qa_status: status }) do
        sprite_icon(icon, size: size, css_class: icon_class)
      end
    end

    def runner_short_name(runner)
      "##{runner.id} (#{runner.short_sha})"
    end

    def runner_link(runner)
      display_name = truncate(runner.display_name, length: 15)
      id = "\##{runner.id}"

      if current_user && current_user.admin
        link_to admin_runner_path(runner) do
          display_name + id
        end
      else
        display_name + id
      end
    end

    def admin_runners_app_data
      data = {
        # Runner install help page is external, located at
        # https://gitlab.com/gitlab-org/gitlab-runner
        runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
        new_runner_path: new_admin_runner_path,
        allow_registration_token: Gitlab::CurrentSettings.allow_runner_registration_token.to_s,
        registration_token: nil,
        online_contact_timeout_secs: ::Ci::Runner::ONLINE_CONTACT_TIMEOUT.to_i,
        stale_timeout_secs: ::Ci::Runner::STALE_TIMEOUT.to_i,
        tag_suggestions_path: tag_list_admin_runners_path(format: :json),
        can_admin_runners: false.to_s
      }

      return data unless current_user.can_admin_all_resources?

      data.merge({
        registration_token: Gitlab::CurrentSettings.runners_registration_token,
        can_admin_runners: true.to_s
      })
    end

    def group_shared_runners_settings_data(group)
      data = {
        group_id: group.id,
        group_name: group.name,
        group_is_empty: (group.projects.empty? && group.children.empty?).to_s,
        shared_runners_setting: group.shared_runners_setting,

        runner_enabled_value: Namespace::SR_ENABLED,
        runner_disabled_value: Namespace::SR_DISABLED_AND_UNOVERRIDABLE,
        runner_allow_override_value: Namespace::SR_DISABLED_AND_OVERRIDABLE,

        parent_shared_runners_setting: group.parent&.shared_runners_setting,
        parent_name: nil,
        parent_settings_path: nil
      }

      if group.parent && can?(current_user, :admin_group, group.parent)
        data.merge!({
          parent_name: group.parent.name,
          parent_settings_path: group_settings_ci_cd_path(group.parent, anchor: 'runners-settings')
        })
      end

      data
    end

    def group_runners_data_attributes(group)
      {
        group_id: group.id,
        group_full_path: group.full_path,
        runner_install_help_page: 'https://docs.gitlab.com/runner/install/',
        online_contact_timeout_secs: ::Ci::Runner::ONLINE_CONTACT_TIMEOUT.to_i,
        stale_timeout_secs: ::Ci::Runner::STALE_TIMEOUT.to_i
      }
    end

    def toggle_shared_runners_settings_data(project)
      data = {
        is_enabled: project.shared_runners_enabled?.to_s,
        is_disabled_and_unoverridable: (project.group&.shared_runners_setting == Namespace::SR_DISABLED_AND_UNOVERRIDABLE).to_s,
        update_path: toggle_shared_runners_project_runners_path(project),
        group_name: nil,
        group_settings_path: nil
      }

      if project.group && can?(current_user, :admin_group, project.group)
        data.merge!({
          group_name: project.group.name,
          group_settings_path: group_settings_ci_cd_path(project.group, anchor: 'runners-settings')
        })
      end

      data
    end
  end
end

Ci::RunnersHelper.prepend_mod_with('Ci::RunnersHelper')
