# frozen_string_literal: true

module Resolvers
  module Projects
    class TagsTippingAtCommitResolver < RefTippingAtCommitResolver
      MAX_LIMIT = 100

      calls_gitaly!

      type ::Types::Projects::CommitParentNamesType, null: true

      # the methode ref_prefix is implemented
      # because this class is prepending Resolver::CommitParentNamesResolver module
      # through it's parent ::Resolvers::RefTippingAtCommitResolver
      def ref_prefix
        Gitlab::Git::TAG_REF_PREFIX
      end
    end
  end
end
