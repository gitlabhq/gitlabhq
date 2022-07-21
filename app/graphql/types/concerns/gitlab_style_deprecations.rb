# frozen_string_literal: true

# Concern for handling deprecation arguments.
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-schema-items
module GitlabStyleDeprecations
  extend ActiveSupport::Concern

  private

  # Mutate the arguments, returns the deprecation
  def gitlab_deprecation(kwargs)
    if kwargs[:deprecation_reason].present?
      raise ArgumentError, 'Use `deprecated` property instead of `deprecation_reason`. ' \
                           'See https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-schema-items'
    end

    # GitLab allows items to be marked as "alpha", which leverages GraphQL deprecations.
    deprecation_args = kwargs.extract!(:alpha, :deprecated)

    deprecation = ::Gitlab::Graphql::Deprecation.parse(**deprecation_args)
    return unless deprecation

    raise ArgumentError, "Bad deprecation. #{deprecation.errors.full_messages.to_sentence}" unless deprecation.valid?

    kwargs[:deprecation_reason] = deprecation.deprecation_reason
    kwargs[:description] = deprecation.edit_description(kwargs[:description])

    deprecation
  end
end
