# frozen_string_literal: true

module Users
  class BaseDismissibleAlertComponent < Pajamas::AlertComponent
    def initialize(args = {})
      @dismiss_options = args.delete(:dismiss_options)

      verify_callout_setup!

      super(**args.merge(dismissible: true, alert_options: build_alert_options(args[:alert_options])))
    end

    private

    attr_reader :dismiss_options

    def render?
      user && !user_dismissed_alert?
    end

    def build_alert_options(alert_options)
      alert_options = alert_options&.dup || {}

      add_css_class(alert_options)
      add_data_attributes(alert_options)

      alert_options
    end

    def add_css_class(alert_options)
      alert_options[:class] = [alert_options[:class], 'js-persistent-callout'].compact.join(' ')
    end

    def add_data_attributes(alert_options)
      data_attributes = build_data_attributes

      add_wrapper_data_attributes!(data_attributes) if respond_to?(:add_wrapper_data_attributes!, true)
      alert_options[:data] = (alert_options[:data] || {}).merge(data_attributes)
    end

    def build_data_attributes
      {
        dismiss_endpoint: dismiss_endpoint,
        feature_id: dismiss_options[:feature_id]
      }
    end

    def dismiss_endpoint
      raise NoMethodError, 'This method must be implemented in a subclass'
    end

    def verify_callout_setup!
      verify_field_presence!(:user)
      verify_feature_id!
    end

    def verify_feature_id!
      feature_id = dismiss_options[:feature_id]
      return if callout_class.feature_names.include?(feature_id)

      raise ArgumentError, "Feature ID '#{feature_id}' not found in #{callout_class}.feature_names"
    end

    def callout_class
      raise NoMethodError, 'This method must be implemented in a subclass'
    end

    def user_dismissed_alert?
      raise NoMethodError, 'This method must be implemented in a subclass'
    end

    def verify_field_presence!(dismiss_option_key)
      return if dismiss_options[dismiss_option_key].present?

      raise ArgumentError, "dismiss_options[#{dismiss_option_key.inspect}] is required"
    end

    def user
      dismiss_options[:user]
    end
  end
end
