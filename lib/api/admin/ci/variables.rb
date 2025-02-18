# frozen_string_literal: true

module API
  module Admin
    module Ci
      class Variables < ::API::Base
        include PaginationParams

        before { authenticated_as_admin! }

        feature_category :ci_variables

        namespace 'admin' do
          namespace 'ci' do
            namespace 'variables' do
              desc 'List all instance-level variables' do
                success Entities::Ci::Variable
                tags %w[ci_variables]
              end
              params do
                use :pagination
              end
              get '/' do
                variables = ::Ci::InstanceVariable.all

                present paginate(variables), with: Entities::Ci::Variable
              end

              desc 'Get the details of a specific instance-level variable' do
                success Entities::Ci::Variable
                failure [{ code: 404, message: 'Instance Variable Not Found' }]
                tags %w[ci_variables]
              end
              params do
                requires :key, type: String, desc: 'The key of a variable'
              end
              get ':key' do
                key = params[:key]
                variable = ::Ci::InstanceVariable.find_by_key(key)

                break not_found!('InstanceVariable') unless variable

                present variable, with: Entities::Ci::Variable
              end

              desc 'Create a new instance-level variable' do
                success Entities::Ci::Variable
                failure [{ code: 400, message: '400 Bad Request' }]
                tags %w[ci_variables]
              end
              route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
              params do
                requires :key,
                  type: String,
                  desc: 'The key of the variable. Max 255 characters'

                optional :description,
                  type: String,
                  desc: 'The description of the variable'

                requires :value,
                  type: String,
                  desc: 'The value of a variable'

                optional :protected,
                  type: Boolean,
                  desc: 'Whether the variable is protected'

                optional :masked,
                  type: Boolean,
                  desc: 'Whether the variable is masked'

                optional :raw,
                  type: Boolean,
                  desc: 'Whether the variable will be expanded'

                optional :variable_type,
                  type: String,
                  values: ::Ci::InstanceVariable.variable_types.keys,
                  desc: 'The type of a variable. Available types are: env_var (default) and file'
              end
              post '/' do
                variable_params = declared_params(include_missing: false)

                variable = ::Ci::InstanceVariable.new(variable_params)

                if variable.save
                  present variable, with: Entities::Ci::Variable
                else
                  render_validation_error!(variable)
                end
              end

              desc 'Update an instance-level variable' do
                success Entities::Ci::Variable
                failure [{ code: 404, message: 'Instance Variable Not Found' }]
                tags %w[ci_variables]
              end
              route_setting :log_safety, { safe: %w[key], unsafe: %w[value] }
              params do
                optional :key,
                  type: String,
                  desc: 'The key of a variable'

                optional :description,
                  type: String,
                  desc: 'The description of the variable'

                optional :value,
                  type: String,
                  desc: 'The value of a variable'

                optional :protected,
                  type: Boolean,
                  desc: 'Whether the variable is protected'

                optional :masked,
                  type: Boolean,
                  desc: 'Whether the variable is masked'

                optional :raw,
                  type: Boolean,
                  desc: 'Whether the variable will be expanded'

                optional :variable_type,
                  type: String,
                  values: ::Ci::InstanceVariable.variable_types.keys,
                  desc: 'The type of a variable. Available types are: env_var (default) and file'
              end
              put ':key' do
                variable = ::Ci::InstanceVariable.find_by_key(params[:key])

                break not_found!('InstanceVariable') unless variable

                variable_params = declared_params(include_missing: false).except(:key)

                if variable.update(variable_params)
                  present variable, with: Entities::Ci::Variable
                else
                  render_validation_error!(variable)
                end
              end

              desc 'Delete an existing instance-level variable' do
                success Entities::Ci::Variable
                failure [{ code: 404, message: 'Instance Variable Not Found' }]
                tags %w[ci_variables]
              end
              params do
                requires :key, type: String, desc: 'The key of a variable'
              end
              delete ':key' do
                variable = ::Ci::InstanceVariable.find_by_key(params[:key])
                not_found!('InstanceVariable') unless variable

                variable.destroy

                no_content!
              end
            end
          end
        end
      end
    end
  end
end
