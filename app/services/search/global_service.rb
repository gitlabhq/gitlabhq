module Search
  class GlobalService
    include Gitlab::CurrentSettings

    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
<<<<<<< HEAD
      if current_application_settings.elasticsearch_search?
        Gitlab::Elastic::SearchResults.new(current_user, params[:search], elastic_projects, elastic_global)
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search])
      end
    end

    def projects
      @projects ||= ProjectsFinder.new(current_user: current_user).execute
    end

    def elastic_projects
      @elastic_projects ||=
        if current_user.try(:admin_or_auditor?)
          :any
        elsif current_user
          current_user.authorized_projects.pluck(:id)
        else
          []
        end
    end

    def elastic_global
      true
=======
      Gitlab::SearchResults.new(current_user, projects, params[:search])
>>>>>>> ce/master
    end

    def projects
      @projects ||= ProjectsFinder.new(current_user: current_user).execute
    end

    def scope
      @scope ||= begin
        allowed_scopes = %w[issues merge_requests milestones]
        allowed_scopes += %w[blobs commits] if current_application_settings.elasticsearch_search?

        allowed_scopes.delete(params[:scope]) { 'projects' }
      end
    end
  end
end
