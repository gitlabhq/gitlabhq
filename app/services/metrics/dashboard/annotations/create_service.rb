# frozen_string_literal: true

# Create Metrics::Dashboard::Annotation entry based on matched dashboard_path, environment, cluster
module Metrics
  module Dashboard
    module Annotations
      class CreateService < ::BaseService
        include Stepable

        steps :authorize_environment_access,
              :authorize_cluster_access,
              :parse_dashboard_path,
              :create

        def initialize(user, params)
          @user = user
          @params = params
        end

        def execute
          execute_steps
        end

        private

        attr_reader :user, :params

        def authorize_environment_access(options)
          if environment.nil? || Ability.allowed?(user, :create_metrics_dashboard_annotation, project)
            options[:environment] = environment
            success(options)
          else
            error(s_('Metrics::Dashboard::Annotation|You are not authorized to create annotation for selected environment'))
          end
        end

        def authorize_cluster_access(options)
          if cluster.nil? || Ability.allowed?(user, :create_metrics_dashboard_annotation, cluster)
            options[:cluster] = cluster
            success(options)
          else
            error(s_('Metrics::Dashboard::Annotation|You are not authorized to create annotation for selected cluster'))
          end
        end

        def parse_dashboard_path(options)
          dashboard_path = params[:dashboard_path]

          Gitlab::Metrics::Dashboard::Finder.find_raw(project, dashboard_path: dashboard_path)
          options[:dashboard_path] = dashboard_path

          success(options)
        rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
          error(s_('Metrics::Dashboard::Annotation|Dashboard with requested path can not be found'))
        end

        def create(options)
          annotation = Annotation.new(options.slice(:environment, :cluster, :dashboard_path).merge(params.slice(:description, :starting_at, :ending_at)))

          if annotation.save
            success(annotation: annotation)
          else
            error(annotation.errors)
          end
        end

        def environment
          params[:environment]
        end

        def cluster
          params[:cluster]
        end

        def project
          (environment || cluster)&.project
        end
      end
    end
  end
end
