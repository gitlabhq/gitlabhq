# frozen_string_literal: true

module Resolvers
  module Projects
    module CommitParentNamesResolver
      extend ActiveSupport::Concern

      prepended do
        argument :commit_sha, GraphQL::Types::String,
          required: true,
          description: 'Project commit SHA identifier. For example, `287774414568010855642518513f085491644061`.'

        argument :limit, GraphQL::Types::Int,
          required: false,
          description: 'Number of branch names to return.'

        alias_method :project, :object
      end

      def compute_limit(limit)
        max = self.class::MAX_LIMIT

        limit ? [limit, max].min : max
      end

      def get_tipping_refs(project, sha, limit: 0)
        # the methode ref_prefix needs to be implemented in all classes prepending this module
        refs = project.repository.refs_by_oid(oid: sha, ref_patterns: [ref_prefix], limit: limit)
        refs.map { |n| n.delete_prefix(ref_prefix) }
      end
    end
  end
end
