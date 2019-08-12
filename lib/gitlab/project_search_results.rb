# frozen_string_literal: true

module Gitlab
  class ProjectSearchResults < SearchResults
    attr_reader :project, :repository_ref

    def initialize(current_user, project, query, repository_ref = nil, per_page: 20)
      @current_user = current_user
      @project = project
      @repository_ref = repository_ref.presence
      @query = query
      @per_page = per_page
    end

    def objects(scope, page = nil)
      case scope
      when 'notes'
        notes.page(page).per(per_page)
      when 'blobs'
        paginated_blobs(blobs, page)
      when 'wiki_blobs'
        paginated_blobs(wiki_blobs, page)
      when 'commits'
        Kaminari.paginate_array(commits).page(page).per(per_page)
      when 'users'
        users.page(page).per(per_page)
      else
        super(scope, page, false)
      end
    end

    def formatted_count(scope)
      case scope
      when 'blobs'
        blobs_count.to_s
      when 'notes'
        formatted_limited_count(limited_notes_count)
      when 'wiki_blobs'
        wiki_blobs_count.to_s
      when 'commits'
        commits_count.to_s
      else
        super
      end
    end

    def users
      super.where(id: @project.team.members) # rubocop:disable CodeReuse/ActiveRecord
    end

    def blobs_count
      @blobs_count ||= blobs.count
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def limited_notes_count
      return @limited_notes_count if defined?(@limited_notes_count)

      types = %w(issue merge_request commit snippet)
      @limited_notes_count = 0

      types.each do |type|
        @limited_notes_count += notes_finder(type).limit(count_limit).count
        break if @limited_notes_count >= count_limit
      end

      @limited_notes_count
    end
    # rubocop: enable CodeReuse/ActiveRecord

    def wiki_blobs_count
      @wiki_blobs_count ||= wiki_blobs.count
    end

    def commits_count
      @commits_count ||= commits.count
    end

    def single_commit_result?
      return false if commits_count != 1

      counts = %i(limited_milestones_count limited_notes_count
                  limited_merge_requests_count limited_issues_count
                  blobs_count wiki_blobs_count)
      counts.all? { |count_method| public_send(count_method).zero? } # rubocop:disable GitlabSecurity/PublicSend
    end

    private

    def paginated_blobs(blobs, page)
      results = Kaminari.paginate_array(blobs).page(page).per(per_page)

      Gitlab::Search::FoundBlob.preload_blobs(results)

      results
    end

    def blobs
      return [] unless Ability.allowed?(@current_user, :download_code, @project)

      @blobs ||= Gitlab::FileFinder.new(project, repository_project_ref).find(query)
    end

    def wiki_blobs
      return [] unless Ability.allowed?(@current_user, :read_wiki, @project)

      @wiki_blobs ||= begin
        if project.wiki_enabled? && query.present?
          unless project.wiki.empty?
            Gitlab::WikiFileFinder.new(project, repository_wiki_ref).find(query)
          else
            []
          end
        else
          []
        end
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

    def commits
      @commits ||= find_commits(query)
    end

    def find_commits(query)
      return [] unless Ability.allowed?(@current_user, :download_code, @project)

      commits = find_commits_by_message(query)
      commit_by_sha = find_commit_by_sha(query)
      commits |= [commit_by_sha] if commit_by_sha
      commits
    end

    def find_commits_by_message(query)
      project.repository.find_commits_by_message(query)
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
