module Gitlab
  class ProjectSearchResults < SearchResults
    attr_reader :project, :repository_ref

    def initialize(project_id, query, repository_ref = nil)
      @project = Project.find(project_id)
      @repository_ref = repository_ref
      @query = Shellwords.shellescape(query) if query.present?
    end

    def objects(scope, page = nil)
      case scope
      when 'notes'
        notes.page(page).per(per_page)
      when 'blobs'
        Kaminari.paginate_array(blobs).page(page).per(per_page)
      else
        super
      end
    end

    def total_count
      @total_count ||= issues_count + merge_requests_count + blobs_count + notes_count
    end

    def blobs_count
      @blobs_count ||= blobs.count
    end

    def notes_count
      @notes_count ||= notes.count
    end

    private

    def blobs
      if project.empty_repo?
        []
      else
        project.repository.search_files(query, repository_ref)
      end
    end

    def notes
      Note.where(project_id: limit_project_ids).search(query).order('updated_at DESC')
    end

    def limit_project_ids
      [project.id]
    end
  end
end
