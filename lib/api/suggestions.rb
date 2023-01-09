# frozen_string_literal: true

module API
  class Suggestions < ::API::Base
    before { authenticate! }

    feature_category :code_review_workflow

    resource :suggestions do
      desc 'Apply suggestion patch in the Merge Request it was created' do
        success Entities::Suggestion
        tags %w[suggestions]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the suggestion'
        optional :commit_message, type: String, desc: "A custom commit message to use instead of the default generated message or the project's default message"
      end
      put ':id/apply', urgency: :low do
        suggestion = Suggestion.find_by_id(params[:id])

        if suggestion
          apply_suggestions(suggestion, current_user, params[:commit_message])
        else
          render_api_error!(_('Suggestion is not applicable as the suggestion was not found.'), :not_found)
        end
      end

      desc 'Apply multiple suggestion patches in the Merge Request where they were created' do
        success Entities::Suggestion
        tags %w[suggestions]
      end
      params do
        requires :ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: "An array of the suggestion IDs"
        optional :commit_message, type: String, desc: "A custom commit message to use instead of the default generated message or the project's default message"
      end
      put 'batch_apply', urgency: :low do
        ids = params[:ids]

        suggestions = Suggestion.id_in(ids)

        if suggestions.size == ids.length
          apply_suggestions(suggestions, current_user, params[:commit_message])
        else
          render_api_error!(_('Suggestions are not applicable as one or more suggestions were not found.'), :not_found)
        end
      end
    end

    helpers do
      def apply_suggestions(suggestions, current_user, message)
        authorize_suggestions(*suggestions)

        result = ::Suggestions::ApplyService.new(current_user, *suggestions, message: message).execute

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
