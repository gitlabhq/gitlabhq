# frozen_string_literal: true

module Users
  class ProjectDismissibleAlertComponent < BaseDismissibleAlertComponent
    include Wrappable
    extend ::Gitlab::Utils::Override

    private

    override :dismiss_endpoint
    def dismiss_endpoint
      ::Gitlab::Routing.url_helpers.project_callouts_path
    end

    override :verify_callout_setup!
    def verify_callout_setup!
      super

      verify_field_presence!(:project)
    end

    override :user_dismissed_alert?
    def user_dismissed_alert?
      user.dismissed_callout_for_project?(
        feature_name: dismiss_options[:feature_id],
        project: dismiss_options[:project],
        ignore_dismissal_earlier_than: dismiss_options[:ignore_dismissal_earlier_than]
      )
    end

    override :build_data_attributes
    def build_data_attributes
      super.merge(project_id: dismiss_options[:project].id)
    end

    override :callout_class
    def callout_class
      Users::ProjectCallout
    end
  end
end
