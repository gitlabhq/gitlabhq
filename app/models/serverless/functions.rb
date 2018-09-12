module Serverless
  class Functions < ActiveRecord::Base
    self.table_name = 'serverless_functions'

    belongs_to :project

    validates :project, presence: true
    validates :runtime_image,
      presence: true,
      length: 2..255

    validates :function_code,
      presence: true

    after_save :create_or_update_function
    after_destroy :destroy_function

    private
    
    def knative_client
      @knative_client ||= project.clusters&.first&.application_knative&.client
    end

    def create_or_update_function
      raise ArgumentError, "knative is not installed" unless knative_client

      @existing_service = knative_client.get_service(name, function_namespace)

      knative_client.update_service(create_metadata)
    rescue ::Kubeclient::HttpError => e
      raise e unless e.error_code == 404

      knative_client.create_service(create_metadata)
    end

    def destroy_function
      return unless knative_client
      
      knative_client.delete_service(name, function_namespace)
    rescue ::Kubeclient::HttpError => e
      raise e unless e.error_code == 404

      false
    end

    def update_metadata
      ::Kubeclient::Resource.new.tap do |r|
        r.metadata = {
          #labels: { project_id: project_id.to_s, function_id: id.to_s }
        }
        r.spec = {
          generation: (@existing_service&.spec || {})[:generation],
          runLatest: {
            configuration: {
              revisionTemplate: {
                spec: {
                  container: {
                    image: runtime_image,
                    env: [
                      { name: 'FUNCTION', value: function_code.to_s }
                    ]
                  }
                }
              }
            }
          }
        }
      end
    end

    def create_metadata
      update_metadata.tap do |r|
        r.apiVersion = 'serving.knative.dev/v1alpha1'
        r.kind = 'Service'
        r.metadata[:name] = name
        r.metadata[:namespace] = function_namespace
        r.metadata[:resourceVersion] = (@existing_service&.metadata || {})[:resourceVersion]
      end
    end

    def function_namespace
      'default'
    end

    # apiVersion: serving.knative.dev/v1alpha1 # Current version of Knative
    # kind: Service
    # metadata:
    #   name: helloworld-go # The name of the app
    #   namespace: default # The namespace the app will use
    # spec:
    #   runLatest:
    #     configuration:
    #       revisionTemplate:
    #         spec:
    #           container:
    #             image: gcr.io/knative-samples/helloworld-go # The URL to the image of the app
    #             env:
    #             - name: TARGET # The environment variable printed out by the sample app
    #               value: "Go Sample v1"
  end
end
