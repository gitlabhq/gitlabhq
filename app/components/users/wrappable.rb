# frozen_string_literal: true

module Users
  module Wrappable
    def initialize(args = {})
      @wrapper_options = args.delete(:wrapper_options)
      super(**args)
    end

    private

    attr_reader :wrapper_options

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
  end
end
