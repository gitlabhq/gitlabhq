# frozen_string_literal: true

module Clusters
  module Applications
    class BaseService
      InvalidApplicationError = Class.new(StandardError)

      attr_reader :cluster, :current_user, :params

      def initialize(cluster, user, params = {})
        @cluster = cluster
        @current_user = user
        @params = params.dup
      end

      def execute(request)
        instantiate_application.tap do |application|
          if application.has_attribute?(:hostname)
            application.hostname = params[:hostname]
          end

          if application.has_attribute?(:email)
            application.email = params[:email]
          end

          if application.has_attribute?(:stack)
            application.stack = params[:stack]
          end

          if application.has_attribute?(:modsecurity_enabled)
            application.modsecurity_enabled = params[:modsecurity_enabled] || false
          end

          if application.respond_to?(:oauth_application)
            application.oauth_application = create_oauth_application(application, request)
          end

          worker = worker_class(application)

          application.make_scheduled!

          worker.perform_async(application.name, application.id)
        end
      end

      protected

      def worker_class(application)
        raise NotImplementedError
      end

      def builder
        raise NotImplementedError
      end

      def project_builders
        raise NotImplementedError
      end

      def instantiate_application
        raise_invalid_application_error if invalid_application?

        builder || raise(InvalidApplicationError, "invalid application: #{application_name}")
      end

      def raise_invalid_application_error
        raise(InvalidApplicationError, "invalid application: #{application_name}")
      end

      def invalid_application?
        unknown_application? || (application_name == Applications::ElasticStack.application_name && !Feature.enabled?(:enable_cluster_application_elastic_stack))
      end

      def unknown_application?
        Clusters::Cluster::APPLICATIONS.keys.exclude?(application_name)
      end

      def application_name
        params[:application]
      end

      def application_class
        Clusters::Cluster::APPLICATIONS[application_name]
      end

      def create_oauth_application(application, request)
        oauth_application_params = {
          name: params[:application],
          redirect_uri: application.callback_url,
          scopes: application.oauth_scopes,
          owner: current_user
        }

        ::Applications::CreateService.new(current_user, oauth_application_params).execute(request)
      end
    end
  end
end
