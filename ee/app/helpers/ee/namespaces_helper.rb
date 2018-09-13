module EE
  module NamespacesHelper
    def namespace_shared_runner_limits_quota(namespace)
      used = namespace.shared_runners_minutes.to_i

      if namespace.shared_runners_minutes_limit_enabled?
        limit = namespace.actual_shared_runners_minutes_limit
        status = namespace.shared_runners_minutes_used? ? 'over_quota' : 'under_quota'
      else
        limit = 'Unlimited'
        status = 'disabled'
      end

      content_tag(:span, class: "shared_runners_limit_#{status}") do
        "#{used} / #{limit}"
      end
    end

    def namespace_shared_runner_limits_percent_used(namespace)
      return 0 unless namespace.shared_runners_minutes_limit_enabled?

      100 * namespace.shared_runners_minutes.to_i / namespace.actual_shared_runners_minutes_limit
    end

    def namespace_shared_runner_limits_progress_bar(namespace)
      percent = [namespace_shared_runner_limits_percent_used(namespace), 100].min

      status =
        if percent == 100
          'danger'
        elsif percent >= 80
          'warning'
        else
          'success'
        end

      options = {
        class: "progress-bar bg-#{status}",
        style: "width: #{percent}%;"
      }

      content_tag :div, class: 'progress' do
        content_tag :div, nil, options
      end
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def namespaces_options_with_developer_maintainer_access(options = {})
      selected = options.delete(:selected) || :current_user
      options[:groups] = current_user.manageable_groups(include_groups_with_developer_maintainer_access: true)
                                     .eager_load(:route)
                                     .order('routes.path')

      namespaces_options(selected, options)
    end
    # rubocop: enable CodeReuse/ActiveRecord
  end
end
