module API
  # RegistryEvents API
  class RegistryEvents < Grape::API
    before { authenticate_container_registry_access_token! }

    content_type :json, 'application/vnd.docker.distribution.events.v1+json'

    params do
      requires :events, type: Array, desc: 'The ID of a project' do
        requires :id, type: String, desc: 'The ID of the event'
        requires :timestamp, type: String, desc: 'Timestamp of the event'
        requires :action, type: String, desc: 'Action performed by event'
        requires :target, type: Hash, desc: 'Target of the event' do
          optional :mediaType, type: String, desc: 'Media type of the target'
          optional :size, type: Integer, desc: 'Size in bytes of the target'
          requires :digest, type: String, desc: 'Digest of the target'
          requires :repository, type: String, desc: 'Repository of target'
          optional :url, type: String, desc: 'Url of the target'
          optional :tag, type: String, desc: 'Tag of the target'
        end
        requires :request, type: Hash, desc: 'Request of the event' do
          requires :id, type: String, desc: 'The ID of the request'
          optional :addr, type: String, desc: 'IP Address of the request client'
          optional :host, type: String, desc: 'Hostname of the registry instance'
          requires :method, type: String, desc: 'Request method'
          requires :useragent, type: String, desc: 'UserAgent header of the request'
        end
        requires :actor, type: Hash, desc: 'Actor that initiated the event' do
          optional :name, type: String, desc: 'Actor name'
        end
        requires :source, type: Hash, desc: 'Source of the event' do
          optional :addr, type: String, desc: 'Hostname of source registry node'
          optional :instanceID, type: String, desc: 'Source registry node instanceID'
        end
      end
    end
    resource :registry_events do
      post do
        params['events'].each do |event|
          repository = event['target']['repository']

          if event['action'] == 'push' && !!event['target']['tag']
            namespace, container_image_name = ContainerImage::split_namespace(repository)
            project = Project::find_by_full_path(namespace)

            if project
              container_image = project.container_images.find_or_create_by(name: container_image_name, path: container_image_name)

              unless container_image.valid?
                render_api_error!({ error: "Failed to create container image!" }, 400)
              end
            else
              not_found!('Project')
            end
          end
        end
      end
    end
  end
end
