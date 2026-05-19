# frozen_string_literal: true

module Gitlab
  module Git
    module Finders
      class BranchesFinder
        include Gitlab::Utils::StrongMemoize

        attr_reader :next_cursor

        # @param repository [Gitlab::Git::Repository] The Git repository to search in
        # @param params [Hash] Search and pagination parameters
        # @option params [String] :search Search pattern (supports ^, $, * operators)
        # @option params [String] :sort Sort order ('name_asc', 'name_desc', 'updated_asc', 'updated_desc')
        # @option params [Integer] :per_page Number of results per page
        # @option params [String] :page_token Opaque cursor for pagination (from previous next_cursor)
        # @param include_commits [Boolean] Whether to hydrate branches with commit data
        #
        # @example Basic search
        #   BranchesFinder.new(repo, search: "feature").execute
        #
        # @example With pagination
        #   finder = BranchesFinder.new(repo, per_page: 20)
        #   first_page = finder.execute
        #   next_page = BranchesFinder.new(repo, per_page: 20, page_token: finder.next_cursor).execute
        #
        # @example With commit data for API responses
        #   BranchesFinder.new(repo, { search: "release" }, include_commits: true).execute
        def initialize(repository, params = {}, include_commits: false)
          @repository = repository
          @params = params
          @include_commits = include_commits
          @next_cursor = nil
        end

        def execute(gitaly_pagination: false) # rubocop:disable Lint/UnusedMethodArgument -- required by GitalyKeysetPager interface
          refs = fetch_refs
          branches = build_branches(refs)
          @next_cursor = refs_finder.next_cursor

          return branches if search.blank? || operator_search?

          set_exact_match_as_first_result(branches)
        end

        def total
          repository.branch_count
        end

        private

        attr_reader :repository, :params, :include_commits

        def fetch_refs
          refs_finder.execute
        end

        def refs_finder
          ref_finder_params = {
            ref_type: :branches,
            sort_by: normalized_sort,
            per_page: effective_per_page,
            page_token: page_token,
            ignore_case: true
          }

          if exact_match_search?
            ref_finder_params[:ref_names] = [search.delete_prefix('^').delete_suffix('$')]
          else
            ref_finder_params[:search] = search_pattern
          end

          RefsFinder.new(repository, **ref_finder_params)
        end
        strong_memoize_attr :refs_finder

        # Builds the complete glob pattern for Gitaly ref listing.
        # Returns a ready-to-use pattern that RefsFinder passes through as-is
        # (RefsFinder treats any pattern containing '*' as pre-built).
        #
        # NOTE: A literal '*' in a branch name cannot be searched exactly through
        # this interface - it is always interpreted as a wildcard operator.
        #
        # Examples:
        #   'foo'    => '**/*foo*'  (contains)
        #   '^foo'   => 'foo*'      (starts with)
        #   'foo$'   => '**/*foo'   (ends with)
        #   '^foo$'  =>  N/A        (exact match - handled via ref_names in fetch_refs)
        #   'f*o'    => '**/*f*o*'  (wildcard)
        def search_pattern
          return if search.blank?

          term = search.delete_prefix('^').delete_suffix('$')
          prefix = search.start_with?('^') ? '' : '**/*'
          suffix = search.end_with?('$') ? '' : '*'

          "#{prefix}#{term}#{suffix}"
        end

        def build_branches(refs)
          return [] if refs.empty?

          if include_commits
            commits = Commit.batch_by_oid(repository, target_page_refs(refs).map(&:target).uniq).index_by(&:id)
            refs.map { |ref| Branch.from_ref(repository, ref, commit: commits[ref.target]) }
          else
            refs.map { |ref| Branch.from_ref(repository, ref) }
          end
        end

        # Promotes the case-insensitive exact match to position 0 for better UX in
        # autocomplete/dropdown scenarios. This is applied intentionally regardless
        # of the active sort order (e.g., even with updated_desc sorting).
        def set_exact_match_as_first_result(branches)
          index = branches.index { |b| b.name.casecmp(search) == 0 }
          return branches if index.nil? || index == 0

          branches.insert(0, branches.delete_at(index))
        end

        def operator_search?
          search.present? &&
            (search.start_with?('^') || search.end_with?('$') || search.include?('*'))
        end

        def exact_match_search?
          search.present? && search.start_with?('^') && search.end_with?('$') && search.exclude?('*')
        end

        # RefsFinder expects 'name_asc' but callers may pass 'name'
        def normalized_sort
          sort = params[:sort].to_s.presence
          sort == 'name' ? 'name_asc' : (sort || 'name_asc')
        end

        def search
          params[:search].to_s.presence
        end
        strong_memoize_attr :search

        def per_page
          params[:per_page]
        end

        def page_token
          params[:page_token]
        end

        # Page-number offset pagination support.
        # These methods are a workaround to support ?page=N offset pagination
        # via GitalyKeysetPager. When page > 1 and page_token is absent,
        # we fetch per_page * page refs from Gitaly so that Kaminari can
        # slice to the correct page, and only hydrate commits for the
        # target page's refs to avoid unnecessary Gitaly calls.

        def page
          params[:page]
        end

        def effective_per_page
          return per_page if page_token.present? || page.blank? || page.to_i <= 1

          per_page * page.to_i
        end

        def offset_page?
          page_token.blank? && page.present? && page.to_i > 1
        end

        def offset
          (page.to_i - 1) * per_page
        end

        def target_page_refs(refs)
          return refs unless offset_page?

          refs[offset, per_page] || []
        end
      end
    end
  end
end
