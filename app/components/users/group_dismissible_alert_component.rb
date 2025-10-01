# frozen_string_literal: true

module Users
  class GroupDismissibleAlertComponent < BaseDismissibleAlertComponent
    include Wrappable
    extend ::Gitlab::Utils::Override

    private

    override :dismiss_endpoint
    def dismiss_endpoint
      ::Gitlab::Routing.url_helpers.group_callouts_path
    end

    override :verify_callout_setup!
    def verify_callout_setup!
      super

      verify_field_presence!(:group)
    end

    override :user_dismissed_alert?
    def user_dismissed_alert?
      user.dismissed_callout_for_group?(
        feature_name: dismiss_options[:feature_id],
        group: dismiss_options[:group],
        ignore_dismissal_earlier_than: dismiss_options[:ignore_dismissal_earlier_than]
      )
    end

    override :build_data_attributes
    def build_data_attributes
      super.merge(group_id: dismiss_options[:group].id)
    end

    override :callout_class
    def callout_class
      Users::GroupCallout
    end
  end
end
