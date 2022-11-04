# frozen_string_literal: true

module SearchArguments
  extend ActiveSupport::Concern

  included do
    argument :search, GraphQL::Types::String,
             required: false,
             description: 'Search query for title or description.'
    argument :in, [Types::IssuableSearchableFieldEnum],
             required: false,
             description: <<~DESC
               Specify the fields to perform the search in.
               Defaults to `[TITLE, DESCRIPTION]`. Requires the `search` argument.'
             DESC
  end

  def ready?(**args)
    validate_search_in_params!(args)
    validate_anonymous_search_access!(args)

    super
  end

  private

  def validate_anonymous_search_access!(args)
    return unless args[:search].present?
    return if current_user.present? || Feature.disabled?(:disable_anonymous_search, type: :ops)

    raise ::Gitlab::Graphql::Errors::ArgumentError,
      "User must be authenticated to include the `search` argument."
  end

  def validate_search_in_params!(args)
    return unless args[:in].present? && args[:search].blank?

    raise Gitlab::Graphql::Errors::ArgumentError,
          '`search` should be present when including the `in` argument'
  end

  def prepare_finder_params(args)
    prepare_search_params(args)
  end

  def prepare_search_params(args)
    return args unless args[:search].present?

    args[:in] = args[:in].join(',') if args[:in].present?
    set_search_optimization_param(args)

    args
  end

  def set_search_optimization_param(args)
    return args unless respond_to?(:resource_parent, true) && resource_parent.present?

    parent_type = resource_parent.is_a?(Project) ? :project : :group
    args[:"attempt_#{parent_type}_search_optimizations"] = true

    args
  end
end
