# frozen_string_literal: true

module Ci
  module RunnersHelper
    include IconsHelper

    def runner_status_icon(runner)
      status = runner.status
      case status
      when :not_connected
        content_tag(:span, title: _("New runner. Has not connected yet")) do
          sprite_icon("warning-solid", size: 24, css_class: "gl-vertical-align-bottom!")
        end

      when :online, :offline, :paused
        content_tag :span, nil,
                    class: "gl-display-inline-block gl-avatar gl-avatar-s16 gl-avatar-circle runner-status runner-status-#{status}",
                    title: _("Runner is %{status}, last contact was %{runner_contact} ago") % { status: status, runner_contact: time_ago_in_words(runner.contacted_at) }
      end
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

    # Due to inability of performing sorting of runners by cached "contacted_at" values we have to show uncached values if sorting by "contacted_asc" is requested.
    # Please refer to the following issue for more details: https://gitlab.com/gitlab-org/gitlab-foss/issues/55920
    def runner_contacted_at(runner)
      if params[:sort] == 'contacted_asc'
        runner.uncached_contacted_at
      else
        runner.contacted_at
      end
    end

    def group_shared_runners_settings_data(group)
      {
        update_path: api_v4_groups_path(id: group.id),
        shared_runners_availability: group.shared_runners_setting,
        parent_shared_runners_availability: group.parent&.shared_runners_setting
      }
    end

    def toggle_shared_runners_settings_data(project)
      {
        is_enabled: "#{project.shared_runners_enabled?}",
        is_disabled_and_unoverridable: "#{project.group&.shared_runners_setting == 'disabled_and_unoverridable'}",
        update_path: toggle_shared_runners_project_runners_path(project)
      }
    end
  end
end

Ci::RunnersHelper.prepend_if_ee('EE::Ci::RunnersHelper')
