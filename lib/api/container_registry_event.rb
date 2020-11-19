# frozen_string_literal: true

module API
  class ContainerRegistryEvent < ::API::Base
    DOCKER_DISTRIBUTION_EVENTS_V1_JSON = 'application/vnd.docker.distribution.events.v1+json'

    feature_category :package_registry

    before { authenticate_registry_notification! }

    resource :container_registry_event do
      helpers do
        def authenticate_registry_notification!
          secret_token = Gitlab.config.registry.notification_secret

          unauthorized! unless Devise.secure_compare(secret_token, headers['Authorization'])
        end
      end

      # Docker Registry sends data in a body of the request as JSON string,
      # by setting 'content_type' we make Grape to parse it automatically
      content_type :json, DOCKER_DISTRIBUTION_EVENTS_V1_JSON
      format :json

      params do
        requires :events, type: Array
      end

      # This endpoint is used by Docker Registry to push a set of event
      # that took place recently.
      post 'events' do
        params['events'].each do |raw_event|
          event = ::ContainerRegistry::Event.new(raw_event)

          if event.supported?
            event.handle!
            event.track!
          end
        end

        status :ok
      end
    end
  end
end
