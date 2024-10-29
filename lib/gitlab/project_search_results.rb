# frozen_string_literal: true

module Gitlab
  class ProjectSearchResults < SearchResults
    attr_reader :project, :repository_ref

    def initialize(current_user, query, project:, repository_ref: nil, order_by: nil, sort: nil, filters: {})
      @project = project
      @repository_ref = repository_ref.presence

      # use the default filter for project searches since we are already limiting by a single project
      super(current_user, query, [project], order_by: order_by, sort: sort, filters: filters, default_project_filter: true)
    end

    def objects(scope, page: nil, per_page: DEFAULT_PER_PAGE, preload_method: nil)
      case scope
      when 'notes'
        notes.page(page).per(per_page)
      when 'blobs'
        paginated_blobs(blobs(limit: limit_up_to_page(page, per_page)), page, per_page)
      when 'wiki_blobs'
        paginated_wiki_blobs(wiki_blobs(limit: limit_up_to_page(page, per_page)), page, per_page)
      when 'commits'
        paginated_commits(page, per_page)
      when 'users'
        users.page(page).per(per_page)
      else
        super(scope, page: page, per_page: per_page, without_count: true)
      end
    end

    def formatted_count(scope)
      case scope
      when 'blobs'
        formatted_limited_count(limited_blobs_count)
      when 'notes'
        formatted_limited_count(limited_notes_count)
      when 'wiki_blobs'
        wiki_blobs_count.to_s
      when 'commits'
        formatted_limited_count(commits_count)
      else
        super
      end
    end

    # rubocop:disable CodeReuse/ActiveRecord
    def users
      results = super

      if @project.is_a?(Array)
        team_members_for_projects = User.joins(:project_authorizations).where(project_authorizations: { project_id: @project })
          .allow_cross_joins_across_databases(url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/422045')
        results = results.where(id: team_members_for_projects)
      else
        results = results.where(id: @project.team.members)
      end

      results
    end
    # rubocop:enable CodeReuse/ActiveRecord

    def limited_blobs_count
      @limited_blobs_count ||= blobs(limit: count_limit).count
    end

    def limited_notes_count
      return @limited_notes_count if defined?(@limited_notes_count)

      types = %w[issue merge_request commit snippet]
      @limited_notes_count = 0

      types.each do |type|
        @limited_notes_count += notes_finder(type).limit(count_limit).count
        break if @limited_notes_count >= count_limit
      end

      @limited_notes_count
    end

    def wiki_blobs_count
      @wiki_blobs_count ||= wiki_blobs(limit: count_limit).count
    end

    def commits_count
      @commits_count ||= commits(limit: count_limit).count
    end

    private

    def paginated_commits(page, per_page)
      results = commits(limit: limit_up_to_page(page, per_page))

      Kaminari.paginate_array(results).page(page).per(per_page)
    end

    def paginated_blobs(blobs, page, per_page)
      results = Kaminari.paginate_array(blobs).page(page).per(per_page)

      Gitlab::Search::FoundBlob.preload_blobs(results)

      results
    end

    def paginated_wiki_blobs(blobs, page, per_page)
      blob_array = paginated_blobs(blobs, page, per_page)
      blob_array.map! do |blob|
        Gitlab::Search::FoundWikiPage.new(blob)
      end
    end

    def limit_up_to_page(page, per_page)
      current_page = page&.to_i || 1
      offset = per_page * (current_page - 1)
      count_limit + offset
    end

    def blobs(limit: count_limit)
      return [] unless Ability.allowed?(@current_user, :read_code, @project)

      @blobs ||= Gitlab::FileFinder.new(project, repository_project_ref).find(query, content_match_cutoff: limit)
    end

    def wiki_blobs(limit: count_limit)
      return [] unless Ability.allowed?(@current_user, :read_wiki, @project)

      @wiki_blobs ||= if project.wiki_enabled? && query.present?
                        if project.wiki.empty?
                          []
                        else
                          Gitlab::WikiFileFinder.new(project, repository_wiki_ref).find(query, content_match_cutoff: limit)
                        end
                      else
                        []
                      end
    end

    def notes
      @notes ||= notes_finder(nil)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def notes_finder(type)
      NotesFinder.new(@current_user, search: query, target_type: type, project: project).execute.user.order('updated_at DESC')
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def commits(limit:)
      @commits ||= find_commits(query, limit: limit)
    end

    def find_commits(query, limit:)
      return [] unless Ability.allowed?(@current_user, :read_code, @project)

      commits = find_commits_by_message(query, limit: limit)
      commit_by_sha = find_commit_by_sha(query)
      commits |= [commit_by_sha] if commit_by_sha
      commits
    end

    def find_commits_by_message(query, limit:)
      project.repository.find_commits_by_message(query, repository_project_ref, nil, limit)
    end

    def find_commit_by_sha(query)
      key = query.strip
      project.repository.commit(key) if Commit.valid_hash?(key)
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def project_ids_relation
      Project.where(id: project).select(:id).reorder(nil)
    end
    # rubocop: enabled CodeReuse/ActiveRecord

    def filter_milestones_by_project(milestones)
      return Milestone.none unless Ability.allowed?(@current_user, :read_milestone, @project)

      milestones.where(project_id: project.id) # rubocop: disable CodeReuse/ActiveRecord
    end

    def repository_project_ref
      @repository_project_ref ||= repository_ref || project.default_branch
    end

    def repository_wiki_ref
      @repository_wiki_ref ||= repository_ref || project.wiki.default_branch
    end

    def issuable_params
      super.merge(project_id: project.id)
    end
  end
end

Gitlab::ProjectSearchResults.prepend_mod_with('Gitlab::ProjectSearchResults')
