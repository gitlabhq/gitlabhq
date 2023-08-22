# frozen_string_literal: true

module Resolvers
  class BlameResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Blame::BlameType, null: true
    calls_gitaly!

    argument :from_line, GraphQL::Types::Int,
      required: false,
      default_value: 1,
      description: 'Range starting from the line. Cannot be less than 1 or greater than `to_line`.'
    argument :to_line, GraphQL::Types::Int,
      required: false,
      default_value: 1,
      description: 'Range ending on the line. Cannot be less than 1 or less than `to_line`.'

    alias_method :blob, :object

    def ready?(**args)
      validate_line_params!(args) if feature_enabled?

      super
    end

    def resolve(from_line:, to_line:)
      return unless feature_enabled?

      authorize!

      Gitlab::Blame.new(blob, blob.repository.commit(blob.commit_id),
        range: (from_line..to_line))
    end

    private

    def authorize!
      read_code? || raise_resource_not_available_error!
    end

    def read_code?
      Ability.allowed?(current_user, :read_code, blob.repository.project)
    end

    def feature_enabled?
      Feature.enabled?(:graphql_git_blame, blob.repository.project)
    end

    def validate_line_params!(args)
      if args[:from_line] <= 0 || args[:to_line] <= 0
        raise Gitlab::Graphql::Errors::ArgumentError,
          '`from_line` and `to_line` must be greater than or equal to 1'
      end

      return unless args[:from_line] > args[:to_line]

      raise Gitlab::Graphql::Errors::ArgumentError,
        '`to_line` must be greater than or equal to `from_line`'
    end
  end
end
