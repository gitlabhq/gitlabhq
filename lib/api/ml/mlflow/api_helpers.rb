# frozen_string_literal: true

module API
  module Ml
    module Mlflow
      module ApiHelpers
        OUTER_QUOTES_REGEXP = /^("|')|("|')?$/
        GITLAB_TAG_PREFIX = 'gitlab.'

        def check_api_read!
          not_found! unless can?(current_user, :read_model_experiments, user_project)
        end

        def check_api_write!
          unauthorized! unless can?(current_user, :write_model_experiments, user_project)
        end

        def check_api_model_registry_read!
          not_found! unless can?(current_user, :read_model_registry, user_project)
        end

        def check_api_model_registry_write!
          unauthorized! unless can?(current_user, :write_model_registry, user_project)
        end

        def resource_not_found!
          render_structured_api_error!({ error_code: 'RESOURCE_DOES_NOT_EXIST' }, 404)
        end

        def resource_already_exists!
          render_structured_api_error!({ error_code: 'RESOURCE_ALREADY_EXISTS' }, 400)
        end

        def invalid_parameter!(message = nil)
          render_structured_api_error!({ error_code: 'INVALID_PARAMETER_VALUE', message: message }, 400)
        end

        def update_failed!
          render_structured_api_error!({ error_code: 'UPDATE_FAILED' }, 400)
        end

        def experiment_repository
          ::Ml::ExperimentTracking::ExperimentRepository.new(user_project, current_user)
        end

        def candidate_repository
          ::Ml::ExperimentTracking::CandidateRepository.new(user_project, current_user)
        end

        def experiment
          @experiment ||= find_experiment!(params[:experiment_id], params[:experiment_name])
        end

        def candidate
          @candidate ||= find_candidate!(params[:run_id])
        end

        def candidates_order_params(params)
          find_params = {
            order_by: nil,
            order_by_type: nil,
            sort: nil
          }

          return find_params if params[:order_by].blank?

          order_by_split = params[:order_by].split(' ')
          order_by_column_split = order_by_split[0].split('.')
          if order_by_column_split.size == 1
            order_by_column = order_by_column_split[0]
            order_by_column_type = 'column'
          elsif order_by_column_split[0] == 'metrics'
            order_by_column = order_by_column_split[1]
            order_by_column_type = 'metric'
          else
            order_by_column = nil
            order_by_column_type = nil
          end

          order_by_sort = order_by_split[1]

          {
            order_by: order_by_column,
            order_by_type: order_by_column_type,
            sort: order_by_sort
          }
        end

        def model_order_params(params)
          if params[:order_by].blank?
            order_by = 'name'
            sort = 'asc'
          else
            order_by, sort = params[:order_by].downcase.split(' ')
            order_by = 'updated_at' if order_by == 'last_updated_timestamp'
            sort ||= 'asc'
          end

          {
            order_by: order_by,
            sort: sort
          }
        end

        def model_filter_params(params)
          return {} if params[:filter].blank?

          param, filter = params[:filter].split('=')

          return {} unless param == 'name'

          filter.gsub!(OUTER_QUOTES_REGEXP, '') unless filter.blank?

          { name: filter }
        end

        def gitlab_tags
          return unless params[:tags].present?

          tags = params[:tags]
          gitlab_params = {}

          tags.each do |tag|
            key, value = tag.values_at(:key, :value)

            gitlab_params[key.delete_prefix(GITLAB_TAG_PREFIX)] = value if key&.starts_with?(GITLAB_TAG_PREFIX)
          end

          gitlab_params
        end

        def custom_version
          return unless gitlab_tags

          gitlab_tags['version']
        end

        def find_experiment!(iid, name)
          experiment_repository.by_iid_or_name(iid: iid, name: name) || resource_not_found!
        end

        def find_candidate!(eid)
          candidate_repository.by_eid(eid) || resource_not_found!
        end

        def find_model(project, name)
          ::Ml::FindModelService.new(project, name).execute || resource_not_found!
        end

        def find_model_version(project, name, version)
          ::Ml::ModelVersions::GetModelVersionService.new(project, name, version).execute || resource_not_found!
        end

        def find_model_artifact(project, version, file_path)
          package = ::Ml::ModelVersion.by_project_id_and_id(project, version).package
          ::Packages::PackageFileFinder.new(package, file_path).execute || resource_not_found!
        end

        def list_model_artifacts(project, version)
          model_version = ::Ml::ModelVersion.by_project_id_and_id(project, version)
          resource_not_found! unless model_version && model_version.package

          model_version.package.installable_package_files
        end

        def model
          @model ||= find_model(user_project, params[:name])
        end
      end
    end
  end
end
