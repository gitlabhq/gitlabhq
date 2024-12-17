# frozen_string_literal: true

##
# DEPRECATED
#
# These helpers are deprecated in favor of detailed CI/CD statuses.
#
# See 'detailed_status?` method and `Gitlab::Ci::Status` module.
#
module Ci
  module StatusHelper
    # rubocop:disable Metrics/CyclomaticComplexity
    def ci_icon_for_status(status, size: 24)
      icon_name =
        if detailed_status?(status)
          status.icon
        else
          case status
          when 'success'
            'status_success'
          when 'success-with-warnings'
            'status_warning'
          when 'failed'
            'status_failed'
          when 'pending'
            'status_pending'
          when 'waiting-for-resource'
            'status_pending'
          when 'preparing'
            'status_preparing'
          when 'running'
            'status_running'
          when 'play'
            'play'
          when 'created'
            'status_created'
          when 'skipped'
            'status_skipped'
          when 'manual'
            'status_manual'
          when 'scheduled'
            'status_scheduled'
          else
            'status_canceled'
          end
        end

      icon_name = icon_name == 'play' ? icon_name : "#{icon_name}_borderless"

      sprite_icon(icon_name, size: size, css_class: 'gl-icon')
    end
    # rubocop:enable Metrics/CyclomaticComplexity

    def render_commit_status(commit, status, ref: nil, tooltip_placement: 'left')
      project = commit.project
      path = pipelines_project_commit_path(project, commit, ref: ref)

      render_ci_icon(
        status,
        path,
        tooltip_placement: tooltip_placement
      )
    end

    def render_ci_icon(
      status,
      path = nil,
      tooltip_placement: 'left',
      container: 'body',
      show_status_text: false
    )
      content_tag_variant = path ? :a : :span
      variant = badge_variant(status)
      badge_classes = "ci-icon ci-icon-variant-#{variant} gl-inline-flex gl-items-center gl-text-sm"
      title = "#{_('Pipeline')}: #{ci_label_for_status(status)}"
      data = { toggle: 'tooltip', placement: tooltip_placement, container: container, testid: 'ci-icon' }

      icon_wrapper_class = "ci-icon-gl-icon-wrapper"

      content_tag(content_tag_variant, href: path, class: badge_classes, title: title, data: data) do
        if show_status_text
          content_tag(:span, ci_icon_for_status(status), { class: icon_wrapper_class }) + content_tag(:span, status.label, { class: 'gl-mx-2 gl-whitespace-nowrap gl-leading-1 gl-self-center', data: { testid: 'ci-icon-text' } })
        else
          content_tag(:span, ci_icon_for_status(status), { class: icon_wrapper_class })
        end
      end
    end

    private

    def detailed_status?(status)
      status.respond_to?(:text) &&
        status.respond_to?(:group) &&
        status.respond_to?(:label) &&
        status.respond_to?(:icon)
    end

    def ci_label_for_status(status)
      return status.label if detailed_status?(status)

      label = case status
              when 'success'
                'passed'
              when 'success-with-warnings'
                'passed with warnings'
              when 'manual'
                'waiting for manual action'
              when 'scheduled'
                'waiting for delayed job'
              else
                status
              end
      translation = "CiStatusLabel|#{label}"
      s_(translation)
    end

    def badge_variant(status)
      variant = detailed_status?(status) ? status.group : status.dasherize

      case variant
      when 'success'
        :success
      when 'success-with-warnings'
        :warning
      when 'pending'
        :warning
      when 'waiting-for-resource'
        :warning
      when 'failed'
        :danger
      when 'running'
        :info
      else
        :neutral
      end
    end
  end
end
