# frozen_string_literal: true

# Concern for handling deprecation arguments.
# https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-fields-and-enum-values
module GitlabStyleDeprecations
  extend ActiveSupport::Concern

  private

  def gitlab_deprecation(kwargs)
    if kwargs[:deprecation_reason].present?
      raise ArgumentError, 'Use `deprecated` property instead of `deprecation_reason`. ' \
                           'See https://docs.gitlab.com/ee/development/api_graphql_styleguide.html#deprecating-fields-and-enum-values'
    end

    deprecation = kwargs.delete(:deprecated)
    return kwargs unless deprecation

    milestone, reason = deprecation.values_at(:milestone, :reason).map(&:presence)

    raise ArgumentError, 'Please provide a `milestone` within `deprecated`' unless milestone
    raise ArgumentError, 'Please provide a `reason` within `deprecated`' unless reason
    raise ArgumentError, '`milestone` must be a `String`' unless milestone.is_a?(String)

    deprecated_in = "Deprecated in #{milestone}"
    kwargs[:deprecation_reason] = "#{reason}. #{deprecated_in}"
    kwargs[:description] += ". #{deprecated_in}: #{reason}" if kwargs[:description]

    kwargs
  end
end
