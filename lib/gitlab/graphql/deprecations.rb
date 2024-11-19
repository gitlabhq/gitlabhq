# frozen_string_literal: true

# Concern for handling GraphQL deprecations.
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-schema-items
module Gitlab
  module Graphql
    module Deprecations
      extend ActiveSupport::Concern

      included do
        attr_accessor :deprecation
      end

      def initialize(*args, **kwargs, &block)
        init_gitlab_deprecation(kwargs)

        super

        update_deprecation_description
      end

      def visible?(ctx)
        super && ctx[:remove_deprecated] == true ? deprecation.nil? : true
      end

      private

      # Set deprecation, mutate the arguments
      def init_gitlab_deprecation(kwargs)
        if kwargs[:deprecation_reason].present?
          raise ArgumentError, <<~ERROR
            Use `deprecated` property instead of `deprecation_reason`. See
            #{Rails.application.routes.url_helpers.help_page_url('development/api_graphql_styleguide.md', anchor: 'deprecating-schema-items')}
          ERROR
        end

        # GitLab allows items to be marked as "experiment", which leverages GraphQL deprecations.
        deprecation_args = kwargs.extract!(:experiment, :deprecated)

        self.deprecation = Deprecation.parse(**deprecation_args)
        return unless deprecation

        unless deprecation.valid?
          raise ArgumentError, "Bad deprecation. #{deprecation.errors.full_messages.to_sentence}"
        end

        kwargs[:deprecation_reason] = deprecation.deprecation_reason
      end

      def update_deprecation_description
        return if deprecation.nil?

        description(deprecation.edit_description(description))
      end
    end
  end
end
