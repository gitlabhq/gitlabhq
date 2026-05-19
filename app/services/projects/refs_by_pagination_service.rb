# frozen_string_literal: true

# Optimally fetches project refs (branches/tags)
# using Gitaly page-token pagination (efficient, forward-only)
module Projects
  class RefsByPaginationService
    include Gitlab::Routing

    def initialize(protected_ref, project, params = {})
      @protected_ref = protected_ref
      @project = project
      @params = params
    end

    def execute
      per_page = params[:per_page] || Kaminari.config.default_per_page

      finder = Gitlab::Git::Finders::RefsFinder.new(
        project.repository.raw_repository,
        ref_type: ref_type,
        search: protected_ref.name,
        per_page: per_page,
        page_token: params[:page_token]
      )

      refs = finder.execute

      refs_with_links(refs, next_cursor: finder.next_cursor)
    end

    private

    attr_reader :protected_ref, :project, :params

    def ref_type
      params[:ref_type] || :branches
    end

    def refs_with_links(refs, next_cursor:)
      previous_path = nil
      next_path = nil

      return [refs, previous_path, next_path] if refs.blank?

      if next_cursor.present?
        next_path = refs_filtered_path(
          page_token: next_cursor,
          sort: params[:sort]
        )
      end

      [refs, previous_path, next_path]
    end

    def refs_filtered_path(options = {})
      if ref_type == :branches
        project_protected_branch_path(project, protected_ref, options)
      elsif ref_type == :tags
        project_protected_tag_path(project, protected_ref, options)
      end
    end
  end
end
