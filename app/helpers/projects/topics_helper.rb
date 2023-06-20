# frozen_string_literal: true

module Projects
  module TopicsHelper
    # To ensure a route will always generate, we need to encode `topic_name`.
    # Otherwise, various pages will encounter `No route matches` error.
    #
    # This does mean some double encoding as Rails ActionDispatch also encodes
    # segments but that is OK
    #
    # Also, controllers that use `params[:topic_name]` will now need to perform
    # decode_www_form_component.
    def topic_explore_projects_cleaned_path(topic_name:)
      topic_name = URI.encode_www_form_component(topic_name) if Feature.enabled?(:explore_topics_cleaned_path)

      topic_explore_projects_path(topic_name: topic_name)
    end
  end
end
