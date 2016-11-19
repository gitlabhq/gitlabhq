module API
  # Projects API
  class Services < Grape::API
    resource :projects do
      before { authenticate! }
      before { authorize_admin_project }

      # Set <service_slug> service for project
      #
      # Example Request:
      #
      #   PUT /projects/:id/services/gitlab-ci
      #
      put ':id/services/:service_slug' do
        if project_service
          validators = project_service.class.validators.select do |s|
            s.class == ActiveRecord::Validations::PresenceValidator &&
              s.attributes != [:project_id]
          end

          required_attributes! validators.map(&:attributes).flatten.uniq
          attrs = attributes_for_keys service_attributes

          if project_service.update_attributes(attrs.merge(active: true))
            true
          else
            not_found!
          end
        end
      end

      # Delete <service_slug> service for project
      #
      # Example Request:
      #
      #   DELETE /project/:id/services/gitlab-ci
      #
      delete ':id/services/:service_slug' do
        if project_service
          attrs = service_attributes.inject({}) do |hash, key|
            hash.merge!(key => nil)
          end

          if project_service.update_attributes(attrs.merge(active: false))
            true
          else
            not_found!
          end
        end
      end

      # Get <service_slug> service settings for project
      #
      # Example Request:
      #
      #   GET /project/:id/services/gitlab-ci
      #
      get ':id/services/:service_slug' do
        present project_service, with: Entities::ProjectService, include_passwords: current_user.is_admin?
      end
    end

    resource :projects do
      desc 'Trigger a slash command' do
        detail 'Added in GitLab 8.13'
      end
      post ':id/services/:service_slug/trigger' do
        project = Project.find_with_namespace(params[:id]) || Project.find_by(id: params[:id])

        # This is not accurate, but done to prevent leakage of the project names
        not_found!('Service') unless project

        service = project_service(project)

        result = service.try(:active?) && service.try(:trigger, params)

        if result
          status result[:status] || 200
          present result
        else
          not_found!('Service')
        end
      end
    end
  end
end
