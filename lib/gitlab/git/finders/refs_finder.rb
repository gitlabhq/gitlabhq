# frozen_string_literal: true

module Gitlab
  module Git
    module Finders
      class RefsFinder
        UnknownRefTypeError = Class.new(StandardError)

        def initialize(repository, ref_type:, search: nil, sort_by: nil)
          @repository = repository
          @search = search
          @ref_type = ref_type
          @sort_by = sort_by
        end

        def execute
          pattern = [prefix, search, "*"].compact.join

          repository.list_refs(
            [pattern],
            sort_by: sort_by
          )
        end

        private

        attr_reader :repository, :search, :ref_type, :sort_by

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
