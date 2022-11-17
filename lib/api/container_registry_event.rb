# frozen_string_literal: true

module API
  class ContainerRegistryEvent < ::API::Base
    DOCKER_DISTRIBUTION_EVENTS_V1_JSON = 'application/vnd.docker.distribution.events.v1+json'

    feature_category :container_registry
    urgency :low

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

      desc 'Receives notifications from the container registry when an operation occurs' do
        detail 'This feature was introduced in GitLab 12.10'
        consumes [:json, DOCKER_DISTRIBUTION_EVENTS_V1_JSON]
      end
      params do
        requires :events, type: Array, desc: 'Event notifications' do
          requires :action, type: String, desc: 'The action to perform, `push`, `delete`',
                            values: %w[push delete].freeze
          optional :target, type: Hash, desc: 'The target of the action' do
            optional :tag, type: String, desc: 'The target tag'
            optional :repository, type: String, desc: 'The target repository'
            optional :digest, type: String, desc: 'Unique identifier for target image manifest'
          end
        end
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
