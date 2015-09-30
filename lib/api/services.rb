module API
  # Projects API
  class Services < Grape::API
    before { authenticate! }
    before { authorize_admin_project }


    resource :projects do
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
        present project_service
      end
    end
  end
end
