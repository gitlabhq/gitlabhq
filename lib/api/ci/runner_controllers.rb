# frozen_string_literal: true

module API
  module Ci
    class RunnerControllers < ::API::Base
      include ::API::PaginationParams

      feature_category :continuous_integration
      before do
        authenticated_as_admin!
      end

      resource :runner_controllers do
        desc 'List runner controllers' do
          detail 'Get all runner controllers.'
          is_array true
          success Entities::Ci::RunnerController
          tags %w[runner_controllers]
          failure [
            { code: 403, message: 'Forbidden' }
          ]
        end
        params do
          use :pagination
        end
        get do
          controllers = ::Ci::RunnerController.all

          present paginate(controllers), with: Entities::Ci::RunnerController
        end

        desc 'Get single runner controller' do
          detail 'Get a runner controller by using the ID of the controller.'
          success Entities::Ci::RunnerController
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[runner_controllers]
        end
        params do
          requires :id, type: Integer, desc: 'ID of the runner controller'
        end
        get ':id' do
          controller = ::Ci::RunnerController.find_by_id(params[:id])

          if controller
            present controller, with: Entities::Ci::RunnerController
          else
            not_found!
          end
        end

        desc 'Register a runner controller' do
          detail 'Register a new runner controller.'
          success Entities::Ci::RunnerController
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 400, message: 'Bad Request' }
          ]
          tags %w[runner_controllers]
        end
        params do
          optional :description, type: String, desc: 'Description of the runner controller',
            documentation: { example: 'Controller for managing runner' }
        end
        post do
          controller = ::Ci::RunnerController.new(description: params[:description])

          if controller.save
            present controller, with: Entities::Ci::RunnerController
          else
            bad_request!(controller.errors.full_messages.to_sentence)
          end
        end

        desc 'Delete a runner controller' do
          detail 'Delete a runner controller by using the ID of the controller.'
          success Entities::Ci::RunnerController
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[runner_controllers]
        end
        params do
          requires :id, type: Integer, desc: 'ID of the runner controller'
        end
        delete ':id' do
          controller = ::Ci::RunnerController.find_by_id(params[:id])

          not_found! unless controller

          destroy_conditionally!(controller) do
            result = controller.destroy

            unless result
              error_message = controller.errors.full_messages.to_sentence
              render_api_error!("Failed to delete runner controller. #{error_message}", 400)
            end
          end
        end
      end
    end
  end
end
