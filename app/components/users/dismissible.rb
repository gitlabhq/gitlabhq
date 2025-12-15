# frozen_string_literal: true

module Users
  module Dismissible
    private

    attr_reader :wrapper_options, :dismiss_options

    # Due to the way rendering in the controller/rack context happens
    # we need to make this a separate module to execute call
    # instead of defining this in the base dismissible class.
    # When we put this in the base dismissible class it renders parent
    # inside of parent as each class along the way will execute a parent
    # render.
    # This placement and then calling inside the child classes
    # solves that.
    def call
      if wrapper_options?
        render_with_wrapper_options(wrapper_options)
      else
        super
      end
    end

    def render?
      user && !user_dismissed?
    end

    def render_with_wrapper_options(options)
      tag_name = options[:tag] || :div
      tag_options = options.except(:tag)

      content_tag(tag_name, render_parent_to_string, tag_options)
    end

    def wrapper_options?
      wrapper_options.present?
    end

    def add_wrapper_data_attributes!(data_attributes)
      data_attributes[:has_wrapper] = wrapper_options?.to_s
    end

    def build_html_options(html_options)
      options = html_options&.dup || {}

      add_css_class(options)
      add_data_attributes(options)

      options
    end

    def add_css_class(html_options)
      html_options[:class] = [html_options[:class], 'js-persistent-callout'].compact.join(' ')
    end

    def add_data_attributes(html_options)
      data_attributes = build_data_attributes

      add_wrapper_data_attributes!(data_attributes)

      html_options[:data] = (html_options[:data] || {}).merge(data_attributes)
    end

    def build_data_attributes
      {
        dismiss_endpoint: dismiss_endpoint,
        feature_id: dismiss_options[:feature_id]
      }
    end

    def dismiss_endpoint
      # no-op overridden in companion module
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
      # no-op overridden in companion module
    end

    def user_dismissed?
      # no-op overridden in companion module
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
