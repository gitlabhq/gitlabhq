# frozen_string_literal: true

module Clusters
  module Applications
    class BaseService
      InvalidApplicationError = Class.new(StandardError)

      FLUENTD_KNOWN_ATTRS = %i[host protocol port waf_log_enabled cilium_log_enabled].freeze

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

          if application.has_attribute?(:modsecurity_mode)
            application.modsecurity_mode = params[:modsecurity_mode] || 0
          end

          apply_fluentd_related_attributes(application)

          if application.respond_to?(:oauth_application)
            application.oauth_application = create_oauth_application(application, request)
          end

          if application.instance_of?(Knative)
            Serverless::AssociateDomainService
              .new(application, pages_domain_id: params[:pages_domain_id], creator: current_user)
              .execute
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
        raise_invalid_application_error if unknown_application?

        builder || raise(InvalidApplicationError, "invalid application: #{application_name}")
      end

      def raise_invalid_application_error
        raise(InvalidApplicationError, "invalid application: #{application_name}")
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

      def apply_fluentd_related_attributes(application)
        FLUENTD_KNOWN_ATTRS.each do |attr|
          application[attr] = params[attr] if application.has_attribute?(attr)
        end
      end
    end
  end
end
