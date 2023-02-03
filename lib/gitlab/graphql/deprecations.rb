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

      def visible?(ctx)
        super && ctx[:remove_deprecated] == true ? deprecation.nil? : true
      end

      private

      # Set deprecation, mutate the arguments
      def init_gitlab_deprecation(kwargs)
        if kwargs[:deprecation_reason].present?
          raise ArgumentError, <<~ERROR
            Use `deprecated` property instead of `deprecation_reason`. See
            #{Rails.application.routes.url_helpers.help_page_url('development/api_graphql_styleguide', anchor: 'deprecating-schema-items')}
          ERROR
        end

        # GitLab allows items to be marked as "alpha", which leverages GraphQL deprecations.
        # TODO remove
        deprecation_args = kwargs.extract!(:alpha, :deprecated)

        self.deprecation = Deprecation.parse(**deprecation_args)
        return unless deprecation

        unless deprecation.valid?
          raise ArgumentError, "Bad deprecation. #{deprecation.errors.full_messages.to_sentence}"
        end

        kwargs[:deprecation_reason] = deprecation.deprecation_reason
        kwargs[:description] = deprecation.edit_description(kwargs[:description])
      end
    end
  end
end
