# frozen_string_literal: true

module Gitlab
  module Git
    module Finders
      class RefsFinder
        UnknownRefTypeError = Class.new(StandardError)

        # @param repository [Gitlab::Git::Repository] The Git repository to search in
        # @param ref_type [Symbol] The type of references to find (:branches or :tags)
        # @param search [String, nil] Search pattern to filter refs by name (supports wildcards)
        # @param sort_by [String, nil] Sort order for results ('name_asc', 'name_desc', 'updated_asc', 'updated_desc')
        # @param per_page [Integer, nil] Number of results per page for pagination
        # @param page_token [String, nil] Token for pagination to get next page of results
        # @param ref_names [Array<String>] List of specific ref names to find (exact match, overrides search)
        #
        # @example Basic search
        #   RefsFinder.new(repo, ref_type: :branches, search: "feat")
        #
        # @example Exact match for specific refs
        #   RefsFinder.new(repo, ref_type: :branches, ref_names: ["master", "develop"])
        #
        # @example With pagination and sorting
        #   RefsFinder.new(repo, ref_type: :tags, sort_by: "name_desc", per_page: 10)
        def initialize(repository, ref_type:, search: nil, sort_by: nil, per_page: nil, page_token: nil, ref_names: [])
          @repository = repository
          @search = search
          @ref_type = ref_type
          @sort_by = sort_by
          @per_page = per_page
          @page_token = page_token
          @ref_names = Array(ref_names)
        end

        def execute
          raw_refs = repository.list_refs(
            patterns,
            sort_by: sort_by,
            pagination_params: pagination_params
          )
          raw_refs.map { |ref| Ref.new(repository, ref.name, ref.target, nil) }
        rescue ArgumentError => e
          raise Gitlab::Git::InvalidPageToken, "Invalid page token: #{page_token}" if e.message.include?('page token')

          raise
        end

        private

        attr_reader :repository, :search, :ref_type, :sort_by, :page_token, :ref_names

        def patterns
          exact_match_pattern || search_pattern
        end

        def exact_match_pattern
          ref_names.select(&:present?).map { |name| [prefix, name].join } if ref_names.present?
        end

        def search_pattern
          # **/* allows to match any level of nesting
          [[prefix, "**/*", search, "*"].compact.join]
        end

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
