module EE
  module GroupsHelper
    def group_shared_runner_limits_quota(group)
      used = group.shared_runners_minutes.to_i

      if group.shared_runners_minutes_limit_enabled?
        limit = group.actual_shared_runners_minutes_limit
        status = group.shared_runners_minutes_used? ? 'over_quota' : 'under_quota'
      else
        limit = 'Unlimited'
        status = 'disabled'
      end

      content_tag(:span, class: "shared_runners_limit_#{status}") do
        "#{used} / #{limit}"
      end
    end

    def group_shared_runner_limits_percent_used(group)
      return 0 unless group.shared_runners_minutes_limit_enabled?

      100 * group.shared_runners_minutes.to_i / group.actual_shared_runners_minutes_limit
    end

    def group_shared_runner_limits_progress_bar(group)
      percent = [group_shared_runner_limits_percent_used(group), 100].min

      status =
        if percent == 100
          'danger'
        elsif percent >= 80
          'warning'
        else
          'success'
        end

      options = {
        class: "progress-bar progress-bar-#{status}",
        style: "width: #{percent}%;"
      }

      content_tag :div, class: 'progress' do
        content_tag :div, nil, options
      end
    end
  end
end
