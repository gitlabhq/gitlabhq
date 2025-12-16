# frozen_string_literal: true

module Users
  module UserDismissible
    include Dismissible
    extend ::Gitlab::Utils::Override

    private

    override :dismiss_endpoint
    def dismiss_endpoint
      ::Gitlab::Routing.url_helpers.callouts_path
    end

    override :callout_class
    def callout_class
      Users::Callout
    end

    override :user_dismissed?
    def user_dismissed?
      user.dismissed_callout?(
        feature_name: dismiss_options[:feature_id],
        ignore_dismissal_earlier_than: dismiss_options[:ignore_dismissal_earlier_than]
      )
    end
  end
end
