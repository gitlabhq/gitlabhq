# frozen_string_literal: true

require 'mime/types'

module API
  # MLFlow integration API, replicating the Rest API https://www.mlflow.org/docs/latest/rest-api.html#rest-api
  module Ml
    module Mlflow
      class RegisteredModels < ::API::Base
        feature_category :mlops

        before do
          check_api_read!
          check_api_model_registry_read!
          check_api_write! if route.settings.dig(:api, :write)
          check_api_model_registry_write! if route.settings.dig(:model_registry, :write)
        end

        resource 'registered-models' do
          desc 'Creates a Registered Model.' do
            success Entities::Ml::Mlflow::RegisteredModel
            detail 'MLFlow Registered Models map to GitLab Models. https://mlflow.org/docs/2.6.0/rest-api.html#create-registeredmodel'
          end
          route_setting :api, write: true
          route_setting :model_registry, write: true
          params do
            requires :name, type: String,
              desc: 'Register models under this name.'
            optional :description, type: String,
              desc: 'Optional description for registered model.'
            optional :tags, type: Array, desc: 'Additional metadata for registered model.'
          end
          post 'create', urgency: :low do
            service_result = ::Ml::CreateModelService.new(
              user_project,
              params[:name],
              current_user,
              params[:description],
              params[:tags]
            ).execute

            resource_already_exists! unless service_result.success?

            present service_result.payload,
              with: Entities::Ml::Mlflow::RegisteredModel,
              root: :registered_model
          rescue ActiveRecord::RecordInvalid
            resource_already_exists!
          end

          desc 'Fetch a Registered Model by Name' do
            success Entities::Ml::Mlflow::RegisteredModel
            detail 'https://www.mlflow.org/docs/1.28.0/rest-api.html#get-registeredmodel'
          end
          params do
            # The name param is actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String, default: '',
              desc: 'Registered model unique name identifier, in reference to the project'
          end
          get 'get', urgency: :low do
            present find_model(user_project, params[:name]), with: Entities::Ml::Mlflow::RegisteredModel,
              root: :registered_model
          end

          desc 'Update a Registered Model by Name' do
            success Entities::Ml::Mlflow::RegisteredModel
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#update-registeredmodel'
          end
          route_setting :api, write: true
          route_setting :model_registry, write: true
          params do
            # The name param is actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String,
              desc: 'Registered model unique name identifier, in reference to the project'
            optional :description, type: String,
              desc: 'Optional description for registered model.'
          end
          patch 'update', urgency: :low do
            present ::Ml::UpdateModelService.new(
              find_model(user_project, params[:name]), params[:description]
            ).execute.payload,
              with: Entities::Ml::Mlflow::RegisteredModel, root: :registered_model
          end

          desc 'Fetch the latest Model Version for the given Registered Model Name' do
            success Entities::Ml::Mlflow::ModelVersion
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#get-latest-modelversions'
          end
          params do
            # The name param is actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String,
              desc: 'Registered model unique name identifier, in reference to the project'
          end
          post 'get-latest-versions', urgency: :low do
            model = find_model(user_project, params[:name])

            present [model.latest_version], with: Entities::Ml::Mlflow::ModelVersion,
              root: :model_versions
          end

          desc 'Delete a Registered Model by Name' do
            success Entities::Ml::Mlflow::RegisteredModel
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#delete-registeredmodel'
          end
          route_setting :api, write: true
          route_setting :model_registry, write: true
          params do
            # The name param is actually required, however it is listed as optional here
            # we can send a custom error response required by MLFlow
            optional :name, type: String,
              desc: 'Registered model unique name identifier, in reference to the project'
          end
          delete 'delete', urgency: :low do
            resource_not_found! unless params[:name]

            model = ::Ml::FindModelService.new(user_project, params[:name]).execute

            resource_not_found! unless model

            if ::Ml::DestroyModelService.new(model, current_user).execute.success?
              present({})
            else
              render_api_error!('Model could not be deleted', 400)
            end
          end

          desc 'Search Registered Models within a project' do
            success Entities::Ml::Mlflow::RegisteredModel
            detail 'https://mlflow.org/docs/2.6.0/rest-api.html#search-registeredmodels'
          end
          params do
            optional :filter,
              type: String,
              desc: "Filter to search models. must be in the format `name='value'`. Only filtering by name is supported"
            optional :max_results,
              type: Integer,
              desc: 'Maximum number of models desired. Default is 200. Max threshold is 1000.',
              default: 200
            optional :order_by,
              type: String,
              desc: 'Order criteria. Can be by name or last_updated_timestamp, with optional DESC or ASC (default)' \
                    'Valid examples: `name`, `name DESC`, `last_updated_timestamp DESC`' \
                    'Sorting by model metadata is not supported.',
              default: 'name ASC'
            optional :page_token,
              type: String,
              desc: 'Token for pagination'
          end
          get 'search', urgency: :low do
            max_results = [params[:max_results], 1000].min

            finder_params = model_order_params(params)
            filter_params = model_filter_params(params)

            if !params[:filter].nil? && !filter_params.key?(:name)
              invalid_parameter!("Invalid attribute key specified. Valid keys are '{'name'}'")
            end

            finder = ::Projects::Ml::ModelFinder.new(user_project, finder_params.merge(filter_params))
            paginator = finder.execute.keyset_paginate(cursor: params[:page_token], per_page: max_results)

            result = {
              registered_models: paginator.records,
              next_page_token: paginator.cursor_for_next_page
            }

            present result, with: Entities::Ml::Mlflow::ListRegisteredModels
          end

          params do
            optional :name, type: String,
              desc: 'The name of the model'
            optional :alias, type: String,
              desc: 'The alias of the model, e.g. the Semantic Version `1.0.0`'
          end
          desc 'Gets a Model Version by alias' do
            detail 'https://mlflow.org/docs/latest/rest-api.html#get-model-version-by-alias'
          end
          get 'alias', urgency: :low do
            present find_model_version(user_project, params[:name], params[:alias]),
              with: Entities::Ml::Mlflow::ModelVersion, root: :model_version
          end
        end
      end
    end
  end
end
