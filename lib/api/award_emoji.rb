module API
  class AwardEmoji < Grape::API
    before { authenticate! }
    AWARDABLES = [Issue, MergeRequest]

    resource :projects do
      AWARDABLES.each do |awardable_type|
        awardable_string = awardable_type.to_s.underscore.pluralize
        awardable_id_string = "#{awardable_type.to_s.underscore}_id"

        [ ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
          ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"
        ].each do |endpoint|
          # Get a list of project +awardable+ award emoji
          #
          # Parameters:
          #   id (required)           - The ID of a project
          #   awardable_id (required) - The ID of an issue or MR
          # Example Request:
          #   GET /projects/:id/issues/:awardable_id/award_emoji
          get endpoint do
            if can_read_awardable?
              awards = paginate(awardable.award_emoji)
              present awards, with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          # Get a specific award emoji
          #
          # Parameters:
          #   id (required)           - The ID of a project
          #   awardable_id (required) - The ID of an issue or MR
          #   award_id (required)     - The ID of the award
          # Example Request:
          #   GET /projects/:id/issues/:awardable_id/award_emoji/:award_id
          get "#{endpoint}/:award_id" do
            if can_read_awardable?
              present awardable.award_emoji.find(params[:award_id]), with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          # Award a new Emoji
          #
          # Parameters:
          #   id (required) - The ID of a project
          #   awardable_id (required) - The ID of an issue or mr
          #   name (required) - The name of a award_emoji (without colons)
          # Example Request:
          #   POST /projects/:id/issues/:awardable_id/award_emoji
          post endpoint do
            required_attributes! [:name]

            not_found!('Award Emoji') unless can_read_awardable? && can_award_awardable?

            award = awardable.create_award_emoji(params[:name], current_user)

            if award.persisted?
              present award, with: Entities::AwardEmoji
            else
              not_found!("Award Emoji #{award.errors.messages}")
            end
          end

          # Delete a +awardables+ award emoji
          #
          # Parameters:
          #   id (required) - The ID of a project
          #   awardable_id (required) - The ID of an issue or MR
          #   award_emoji_id (required) - The ID of an award emoji
          # Example Request:
          #   DELETE /projects/:id/issues/:issue_id/notes/:note_id/award_emoji/:award_id
          delete "#{endpoint}/:award_id" do
            award = awardable.award_emoji.find(params[:award_id])

            unauthorized! unless award.user == current_user || current_user.admin?

            award.destroy
            present award, with: Entities::AwardEmoji
          end
        end
      end
    end

    helpers do
      def can_read_awardable?
        ability = "read_#{awardable.class.to_s.underscore}".to_sym

        can?(current_user, ability, awardable)
      end

      def can_award_awardable?
        awardable.user_can_award?(current_user, params[:name])
      end

      def awardable
        @awardable ||=
          begin
            if params.include?(:note_id)
              noteable.notes.find(params[:note_id])
            else
              noteable
            end
          end
      end

      def noteable
        if params.include?(:issue_id)
          user_project.issues.find(params[:issue_id])
        else
          user_project.merge_requests.find(params[:merge_request_id])
        end
      end
    end
  end
end
