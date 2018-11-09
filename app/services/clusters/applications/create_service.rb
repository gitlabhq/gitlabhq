# frozen_string_literal: true

module Clusters
  module Applications
    class CreateService
      InvalidApplicationError = Class.new(StandardError)

      attr_reader :cluster, :current_user, :params

      def initialize(cluster, user, params = {})
        @cluster = cluster
        @current_user = user
        @params = params.dup
      end

      def execute(request)
        create_application.tap do |application|
          if application.has_attribute?(:hostname)
            application.hostname = params[:hostname]
          end

          if application.respond_to?(:oauth_application)
            application.oauth_application = create_oauth_application(application, request)
          end

          application.save!

          Clusters::Applications::ScheduleInstallationService.new(application).execute
        end
      end

      private

      def create_application
        builder.call(@cluster)
      end

      def builder
        builders[application_name] || raise(InvalidApplicationError, "invalid application: #{application_name}")
      end

      def builders
        {
          "helm" => -> (cluster) { cluster.application_helm || cluster.build_application_helm },
          "ingress" => -> (cluster) { cluster.application_ingress || cluster.build_application_ingress }
        }.tap do |hash|
          hash.merge!(project_builders) if cluster.project_type?
        end
      end

      # These applications will need extra configuration to enable them to work
      # with groups of projects
      def project_builders
        {
          "prometheus" => -> (cluster) { cluster.application_prometheus || cluster.build_application_prometheus },
          "runner" => -> (cluster) { cluster.application_runner || cluster.build_application_runner },
          "jupyter" => -> (cluster) { cluster.application_jupyter || cluster.build_application_jupyter },
          "knative" => -> (cluster) { cluster.application_knative || cluster.build_application_knative }
        }
      end

      def application_name
        params[:application]
      end

      def create_oauth_application(application, request)
        oauth_application_params = {
          name: params[:application],
          redirect_uri: application.callback_url,
          scopes: 'api read_user openid',
          owner: current_user
        }

        ::Applications::CreateService.new(current_user, oauth_application_params).execute(request)
      end
    end
  end
end
