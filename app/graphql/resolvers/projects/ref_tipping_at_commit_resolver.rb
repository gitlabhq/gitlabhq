# frozen_string_literal: true

module Resolvers
  module Projects
    class RefTippingAtCommitResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      prepend CommitParentNamesResolver

      type ::Types::Projects::CommitParentNamesType, null: true

      authorize :read_code

      def resolve(commit_sha:, limit: nil)
        final_limit = compute_limit(limit)

        names = get_tipping_refs(project, commit_sha, limit: final_limit)

        {
          names: names,
          total_count: nil
        }
      end
    end
  end
end
