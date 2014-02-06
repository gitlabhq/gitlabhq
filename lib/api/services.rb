module API
  # Projects API
  class Services < Grape::API
    before { authenticate! }
    before { authorize_admin_project }

    resource :projects do
      # Set GitLab CI service for project
      #
      # Parameters:
      #   token (required) - CI project token
      #   project_url (required) - CI project url
      #
      # Example Request:
      #   PUT /projects/:id/services/gitlab-ci
      put ":id/services/gitlab-ci" do
        required_attributes! [:token, :project_url]
        attrs = attributes_for_keys [:token, :project_url]
        user_project.build_missing_services

        if user_project.gitlab_ci_service.update_attributes(attrs.merge(active: true))
          true
        else
          not_found!
        end
      end

      # Delete GitLab CI service settings
      #
      # Example Request:
      #   DELETE /projects/:id/keys/:id
      delete ":id/services/gitlab-ci" do
        if user_project.gitlab_ci_service
          user_project.gitlab_ci_service.update_attributes(
            active: false,
            token: nil,
            project_url: nil
          )
        end
      end
    end
  end
end

