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
    validate_search_rate_limit!(args)

    super
  end

  private

  def validate_search_in_params!(args)
    return unless args[:in].present? && args[:search].blank?

    raise Gitlab::Graphql::Errors::ArgumentError,
      '`search` should be present when including the `in` argument'
  end

  def validate_search_rate_limit!(args)
    return if args[:search].blank? || context[:request].nil?

    if current_user.present?
      rate_limiter_key = :search_rate_limit
      rate_limiter_scope = [current_user]
    else
      rate_limiter_key = :search_rate_limit_unauthenticated
      rate_limiter_scope = [context[:request].ip]
    end

    if ::Gitlab::ApplicationRateLimiter.throttled_request?(
      context[:request],
      current_user,
      rate_limiter_key,
      scope: rate_limiter_scope
    )
      raise Gitlab::Graphql::Errors::ResourceNotAvailable,
        'This endpoint has been requested with the search argument too many times. Try again later.'
    end
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
