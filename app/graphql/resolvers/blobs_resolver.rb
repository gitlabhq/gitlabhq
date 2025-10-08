# frozen_string_literal: true

module Resolvers
  class BlobsResolver < BaseResolver
    include Gitlab::Graphql::Authorize::AuthorizeResource

    type Types::Tree::BlobType.connection_type, null: true
    authorize :read_code
    calls_gitaly!

    alias_method :repository, :object

    argument :paths, [GraphQL::Types::String],
      required: true,
      description: 'Array of desired blob paths.'
    argument :ref, GraphQL::Types::String,
      required: false,
      default_value: nil,
      description: 'Commit ref to get the blobs from. Default value is HEAD.'
    argument :ref_type, Types::RefTypeEnum,
      required: false,
      default_value: nil,
      description: 'Type of ref.'

    # We fetch blobs from Gitaly efficiently but it still scales O(N) with the
    # number of paths being fetched, so apply a scaling limit to that.
    def self.resolver_complexity(args, child_complexity:)
      super + (args[:paths] || []).size
    end

    def resolve(paths:, ref:, ref_type:)
      authorize!(repository.container)

      return [] if repository.empty?

      ref ||= repository.root_ref
      validate_ref(ref)

      ref = ExtractsRef::RefExtractor.qualify_ref(ref, ref_type)

      repository.blobs_at(paths.map { |path| [ref, path] }).tap do |blobs|
        blobs.each do |blob|
          blob.ref_type = ref_type
        end
      end
    end

    private

    def validate_ref(ref)
      return if Gitlab::GitRefValidator.validate(ref, skip_head_ref_check: true)

      raise Gitlab::Graphql::Errors::ArgumentError, 'Ref is not valid'
    end
  end
end
