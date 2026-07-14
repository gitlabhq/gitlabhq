# frozen_string_literal: true

module API
  class Suggestions < ::API::Base
    before { authenticate! }

    feature_category :code_review_workflow

    resource :suggestions do
      desc 'Apply a suggestion to a merge request' do
        detail 'Applies a suggested patch in a merge request. You must have the Developer, ' \
          'Maintainer, or Owner role.'
        success Entities::Suggestion
        tags %w[suggestions]
      end
      params do
        requires :id, type: Integer, desc: 'The ID of the suggestion'
        optional :commit_message, type: String, desc: "A custom commit message to use instead of the default generated message or the project's default message"
      end
      route_setting :authorization, permissions: :apply_suggestion,
        boundary: -> { find_suggestion&.note&.project }, boundary_type: :project
      put ':id/apply', urgency: :low do
        suggestion = find_suggestion

        if suggestion
          apply_suggestions(suggestion, current_user, params[:commit_message])
        else
          render_api_error!(_('Suggestion is not applicable as the suggestion was not found.'), :not_found)
        end
      end

      desc 'Apply multiple suggestions to a merge request' do
        detail 'Applies multiple suggested patches in a merge request. You must have the ' \
          'Developer, Maintainer, or Owner role.'
        success Entities::Suggestion
        tags %w[suggestions]
      end
      params do
        requires :ids, type: Array[Integer], coerce_with: ::API::Validations::Types::CommaSeparatedToIntegerArray.coerce, desc: "An array of the suggestion IDs"
        optional :commit_message, type: String, desc: "A custom commit message to use instead of the default generated message or the project's default message"
      end
      route_setting :authorization, permissions: :apply_suggestion,
        boundary: -> { find_suggestions.first&.note&.project }, boundary_type: :project
      put 'batch_apply', urgency: :low do
        ids = params[:ids]

        suggestions = find_suggestions

        if suggestions.size == ids.length
          apply_suggestions(suggestions, current_user, params[:commit_message])
        else
          render_api_error!(_('Suggestions are not applicable as one or more suggestions were not found.'), :not_found)
        end
      end
    end

    helpers do
      def find_suggestion
        @suggestion ||= Suggestion.find_by_id(params[:id])
      end

      def find_suggestions
        @suggestions ||= Suggestion.id_in(params[:ids]).to_a
      end

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
