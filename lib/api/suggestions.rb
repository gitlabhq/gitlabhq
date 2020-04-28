# frozen_string_literal: true

module API
  class Suggestions < Grape::API
    before { authenticate! }

    resource :suggestions do
      desc 'Apply suggestion patch in the Merge Request it was created' do
        success Entities::Suggestion
      end
      params do
        requires :id, type: String, desc: 'The suggestion ID'
      end
      put ':id/apply' do
        suggestion = Suggestion.find_by_id(params[:id])

        not_found! unless suggestion
        authorize! :apply_suggestion, suggestion

        result = ::Suggestions::ApplyService.new(current_user).execute(suggestion)

        if result[:status] == :success
          present suggestion, with: Entities::Suggestion, current_user: current_user
        else
          http_status = result[:http_status] || 400
          render_api_error!(result[:message], http_status)
        end
      end
    end
  end
end
