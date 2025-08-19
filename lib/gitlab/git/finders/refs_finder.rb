# frozen_string_literal: true

module Gitlab
  module Git
    module Finders
      class RefsFinder
        UnknownRefTypeError = Class.new(StandardError)

        def initialize(repository, ref_type:, search: nil, sort_by: nil, per_page: nil, page_token: nil)
          @repository = repository
          @search = search
          @ref_type = ref_type
          @sort_by = sort_by
          @per_page = per_page
          @page_token = page_token
        end

        def execute
          # **/* allows to match any level of nesting
          pattern = [prefix, "**/*", search, "*"].compact.join

          repository.list_refs(
            [pattern],
            sort_by: sort_by,
            pagination_params: pagination_params
          )
        rescue ArgumentError => e
          raise Gitlab::Git::InvalidPageToken, "Invalid page token: #{page_token}" if e.message.include?('page token')

          raise
        end

        private

        attr_reader :repository, :search, :ref_type, :sort_by, :page_token

        def pagination_params
          return unless @per_page

          { limit: per_page, page_token: page_token }.compact
        end

        def per_page
          Gitlab::PaginationDelegate.new(
            per_page: @per_page.presence, page: nil, count: nil
          ).limit_value
        end

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
