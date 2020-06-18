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

        if suggestion
          apply_suggestions(suggestion, current_user)
        else
          render_api_error!(_('Suggestion is not applicable as the suggestion was not found.'), :not_found)
        end
      end

      desc 'Apply multiple suggestion patches in the Merge Request where they were created' do
        success Entities::Suggestion
      end
      params do
        requires :ids, type: Array[String], desc: "An array of suggestion ID's"
      end
      put 'batch_apply' do
        ids = params[:ids]

        suggestions = Suggestion.id_in(ids)

        if suggestions.size == ids.length
          apply_suggestions(suggestions, current_user)
        else
          render_api_error!(_('Suggestions are not applicable as one or more suggestions were not found.'), :not_found)
        end
      end
    end

    helpers do
      def apply_suggestions(suggestions, current_user)
        authorize_suggestions(*suggestions)

        result = ::Suggestions::ApplyService.new(current_user, *suggestions).execute

        if result[:status] == :success
          present suggestions, with: Entities::Suggestion, current_user: current_user
        else
          http_status = result[:http_status] || :bad_request
          render_api_error!(result[:message], http_status)
        end
      end

      def authorize_suggestions(*suggestions)
        suggestions.each do |suggestion|
          authorize! :apply_suggestion, suggestion
        end
      end
    end
  end
end
