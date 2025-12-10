# frozen_string_literal: true

module API
  module Ci
    class RunnerControllerTokens < ::API::Base
      include ::API::PaginationParams

      feature_category :continuous_integration

      before do
        authenticated_as_admin!
      end

      resource :runner_controllers do
        desc 'List runner controller tokens' do
          detail 'Get all tokens for a specific runner controller.'
          is_array true
          success Entities::Ci::RunnerControllerToken
          tags %w[runner_controller_tokens]
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
        end
        params do
          requires :runner_controller_id, type: Integer, desc: 'ID of the runner controller'
          use :pagination
        end
        get ':runner_controller_id/tokens' do
          controller = ::Ci::RunnerController.find_by_id(params[:runner_controller_id])
          not_found! unless controller

          tokens = controller.tokens
          present paginate(tokens), with: Entities::Ci::RunnerControllerToken
        end

        desc 'Get single runner controller token' do
          detail 'Get a token for a specific runner controller by using the ID of the token.'
          success Entities::Ci::RunnerControllerToken
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[runner_controller_tokens]
        end
        params do
          requires :runner_controller_id, type: Integer, desc: 'ID of the runner controller'
          requires :id, type: Integer, desc: 'ID of the runner controller token'
        end
        get ':runner_controller_id/tokens/:id' do
          controller = ::Ci::RunnerController.find_by_id(params[:runner_controller_id])
          not_found! unless controller

          token = controller.tokens.find_by_id(params[:id])
          if token
            present token, with: Entities::Ci::RunnerControllerToken
          else
            not_found!
          end
        end

        desc 'Create a runner controller token' do
          detail 'Create a new token for a specific runner controller.'
          success Entities::Ci::RunnerControllerToken
          failure [
            { code: 403, message: 'Forbidden' },
            { code: 400, message: 'Bad Request' },
            { code: 404, message: 'Not found' }
          ]
          tags %w[runner_controller_tokens]
        end
        params do
          requires :runner_controller_id, type: Integer, desc: 'ID of the runner controller'
          optional :description, type: String, desc: 'Description of the runner controller token',
            documentation: { example: 'Token for managing runner' }
        end
        post ':runner_controller_id/tokens' do
          controller = ::Ci::RunnerController.find_by_id(params[:runner_controller_id])
          not_found! unless controller

          token = controller.tokens.new(description: params[:description])

          if token.save
            present token, with: Entities::Ci::RunnerControllerTokenWithToken
          else
            bad_request!(token.errors.full_messages.to_sentence)
          end
        end
      end
    end
  end
end
