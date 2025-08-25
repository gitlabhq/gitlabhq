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

      refs = Gitlab::Git::Finders::RefsFinder.new(
        project.repository.raw_repository,
        ref_type: ref_type,
        search: protected_ref.name,
        per_page: per_page + 1,
        page_token: params[:page_token]
      ).execute

      last_page = refs.size <= per_page

      refs = refs.take(per_page) # rubocop:disable CodeReuse/ActiveRecord -- There is no ActiveRecord model for raw Gitaly references

      refs_with_links(refs, last_page: last_page)
    end

    private

    attr_reader :protected_ref, :project, :params

    def ref_type
      params[:ref_type] || :branches
    end

    def refs_with_links(refs, last_page:)
      previous_path = nil
      next_path = nil

      return [refs, previous_path, next_path] if refs.blank?

      unless last_page
        next_path = refs_filtered_path(
          page_token: next_page_token(refs.last.name),
          sort: params[:sort]
        )
      end

      [refs, previous_path, next_path]
    end

    def next_page_token(name)
      case ref_type
      when :branches
        "#{Gitlab::Git::BRANCH_REF_PREFIX}#{name}"
      when :tags
        "#{Gitlab::Git::TAG_REF_PREFIX}#{name}"
      end
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
