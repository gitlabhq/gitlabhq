module Search
  class GlobalService
    include Gitlab::CurrentSettings

    attr_accessor :current_user, :params

    def initialize(user, params)
      @current_user, @params = user, params.dup
    end

    def execute
      group = Group.find_by(id: params[:group_id]) if params[:group_id].present?
      projects = ProjectsFinder.new(current_user: current_user).execute

      if group
        projects = projects.inside_path(group.full_path)
      end

      if current_application_settings.elasticsearch_search?
        projects_spec =
          if group
            projects.pluck(:id)
          else
            if current_user && current_user.admin_or_auditor?
              :any
            elsif current_user
              current_user.authorized_projects.pluck(:id)
            else
              []
            end
          end

        Gitlab::Elastic::SearchResults.new(
          current_user,
          params[:search],
          projects_spec,
          !group # Ignore public projects outside of the group if provided
        )
      else
        Gitlab::SearchResults.new(current_user, projects, params[:search])
      end
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
