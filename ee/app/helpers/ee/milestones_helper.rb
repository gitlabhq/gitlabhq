module EE
  module MilestonesHelper
    def burndown_chart(milestone)
      Burndown.new(milestone) if milestone.supports_burndown_charts?
    end

    def can_generate_chart?(milestone, burndown)
      return false unless milestone.supports_burndown_charts?

      burndown&.valid? && !burndown&.empty?
    end

    def show_burndown_placeholder?(milestone, warning)
      return false if cookies['hide_burndown_message'].present?
      return false unless milestone.supports_burndown_charts?

      warning.nil? && can_admin_milestone?(milestone)
    end

    def data_warning_for(burndown)
      return unless burndown

      message =
        if burndown.empty?
          "The burndown chart can’t be shown, as all issues assigned to this milestone were closed on an older GitLab version before data was recorded. "
        elsif !burndown.accurate?
          "Some issues can’t be shown in the burndown chart, as they were closed on an older GitLab version before data was recorded. "
        end

      if message
        message += link_to "About burndown charts", help_page_path('user/project/milestones/index', anchor: 'burndown-charts'), class: 'burndown-docs-link'

        content_tag(:div, message.html_safe, id: "data-warning", class: "settings-message prepend-top-20")
      end
    end

    private

    def can_admin_milestone?(milestone)
      policy_name = milestone.group_milestone? ? :admin_milestones : :admin_milestone

      can?(current_user, policy_name, milestone.parent)
    end
  end
end
