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
    argument :ignore_revs, GraphQL::Types::Boolean,
      required: false,
      default_value: false,
      description: 'Enable to ignore revisions in the `.git-ignore-revs-file` when fetching the blame.'
    argument :to_line, GraphQL::Types::Int,
      required: false,
      default_value: 1,
      description: 'Range ending on the line. Cannot be smaller than `from_line` or greater than `from_line` + 100.'

    alias_method :blob, :object

    def ready?(**args)
      validate_line_params!(args)

      super
    end

    def resolve(from_line:, to_line:, ignore_revs:)
      authorize!

      Gitlab::Blame.new(
        blob, blob.repository.commit(blob.commit_id), range: (from_line..to_line), ignore_revs: ignore_revs
      )
    rescue Gitlab::Git::Blame::IgnoreRevsFileError
      raise GraphQL::ExecutionError, "Could not resolve ignore-revisions file (`#{ignore_revisions_ref}`)."
    rescue Gitlab::Git::Blame::IgnoreRevsFormatError
      raise GraphQL::ExecutionError, "The ignore-revisions file (`#{ignore_revisions_ref}`) contains invalid revisions."
    end

    private

    def authorize!
      read_code? || raise_resource_not_available_error!
    end

    def read_code?
      Ability.allowed?(current_user, :read_code, project)
    end

    def validate_line_params!(args)
      raise_greater_than_one unless args[:from_line] >= 1
      raise_greater_than_one unless args[:to_line] >= 1

      return unless args[:to_line] < args[:from_line] || args[:to_line] >= args[:from_line] + 100

      raise Gitlab::Graphql::Errors::ArgumentError,
        '`to_line` must be greater than or equal to `from_line` and smaller than `from_line` + 100'
    end

    def raise_greater_than_one
      raise Gitlab::Graphql::Errors::ArgumentError,
        '`from_line` and `to_line` must be greater than or equal to 1'
    end

    def project
      blob.repository.project
    end

    def ignore_revisions_ref
      "refs/heads/#{project.default_branch}:#{Gitlab::Blame::IGNORE_REVS_FILE_NAME}"
    end
  end
end
