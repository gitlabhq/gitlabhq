# frozen_string_literal: true

module Gitlab
  module Git
    module Finders
      class RefsFinder
        attr_reader :repository, :search, :ref_type

        UnknownRefTypeError = Class.new(StandardError)

        def initialize(repository, search:, ref_type:)
          @repository = repository
          @search = search
          @ref_type = ref_type
        end

        def execute
          pattern = [prefix, search, "*"].compact.join

          repository.list_refs(
            [pattern]
          )
        end

        private

        def prefix
          case ref_type
          when :branches
            Gitlab::Git::BRANCH_REF_PREFIX
          when :tags
            Gitlab::Git::TAG_REF_PREFIX
          else
            raise UnknownRefTypeError, "ref_type must be one of [:branches, :tags]"
          end
        end
      end
    end
  end
end
