module Search
  class ProjectService
    attr_accessor :project, :current_user, :params

    def initialize(project, user, params)
      @project, @current_user, @params = project, user, params.dup
    end

    def execute
      query = params[:search]
      query = Shellwords.shellescape(query) if query.present?
      return result unless query.present?

      if params[:search_code].present?
        blobs = project.repository.search_files(query, params[:repository_ref]) unless project.empty_repo?
        blobs = Kaminari.paginate_array(blobs).page(params[:page]).per(20)
        result[:blobs] = blobs
        result[:total_results] = blobs.total_count
      else
        result[:merge_requests] = project.merge_requests.search(query).order('updated_at DESC').limit(20)
        result[:issues] = project.issues.where("title like :query OR description like :query ", query: "%#{query}%").order('updated_at DESC').limit(20)
        result[:notes] = Note.where(noteable_type: 'issue').where(project_id: project.id).where("note like :query", query: "%#{query}%").order('updated_at DESC').limit(20)
        result[:total_results] = %w(issues merge_requests notes).sum { |items| result[items.to_sym].size }
      end

      result
    end

    def result
      @result ||= {
        merge_requests: [],
        issues: [],
        blobs: [],
        notes: [],
        total_results: 0,
      }
    end
  end
end
