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
    argument :ref_type, GraphQL::Types::String,
             required: false,
             default_value: nil,
             description: 'Type of the ref. heads for branches and tags for tags.'

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

      ref = fully_qualifed_ref(ref, ref_type)

      repository.blobs_at(paths.map { |path| [ref, path] }).tap do |blobs|
        blobs.each do |blob|
          blob.ref_type = ref_type
        end
      end
    end

    private

    def fully_qualifed_ref(ref, ref_type)
      return ref unless ref_type.present? && Feature.enabled?(:use_ref_type_parameter, repository.project)

      ref_type = ref_type == 'tags' ? 'tags' : 'heads'
      %(refs/#{ref_type}/#{ref})
    end

    def validate_ref(ref)
      unless Gitlab::GitRefValidator.validate(ref)
        raise Gitlab::Graphql::Errors::ArgumentError, 'Ref is not valid'
      end
    end
  end
end
