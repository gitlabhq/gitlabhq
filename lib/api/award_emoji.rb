module API
  class AwardEmoji < Grape::API
    before { authenticate! }

    AWARDABLES = [Issue, MergeRequest]

    resource :projects do
      AWARDABLES.each do |awardable_type|
        awardable_string = awardable_type.to_s.underscore.pluralize
        awardable_id_string = "#{awardable_type.to_s.underscore}_id"

        # Get a list of project +awardable+ award emoji
        #
        # Parameters:
        #   id (required)           - The ID of a project
        #   awardable_id (required) - The ID of an issue or MR
        # Example Request:
        #   GET /projects/:id/issues/:awardable_id/award_emoji
        get ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji" do
          awardable = user_project.send(awardable_string.to_sym).find(params[awardable_id_string.to_sym])

          if can?(current_user, awardable_read_ability_name(awardable), awardable)
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
        get ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji/:award_id" do
          awardable = user_project.send(awardable_string.to_sym).find(params[awardable_id_string.to_sym])

          if can?(current_user, awardable_read_ability_name(awardable), awardable)
            present awardable.award_emoji.find(params[:award_id]), with: Entities::AwardEmoji
          else
            not_found!("Award Emoji")
          end
        end

        # Award a new Emoji
        #
        # Parameters:
        #   id (required) - The ID of a project
        #   noteable_id (required) - The ID of an issue or snippet
        #   name (required) - The name of a award_emoji (without colons)
        # Example Request:
        #   POST /projects/:id/issues/:noteable_id/notes
        #   POST /projects/:id/snippets/:noteable_id/notes
        post ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji" do
          required_attributes! [:name]

          awardable = user_project.send(awardable_string.to_sym).find(params[awardable_id_string.to_sym])
          not_found!('Award Emoji') unless can?(current_user, awardable_read_ability_name(awardable), awardable)

          award = awardable.award_emoji.new(name: params[:name], user: current_user)

          if award.save
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
        #   DELETE /projects/:id/issues/:noteable_id/notes/:note_id
        delete ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji/:award_id" do
          awardable = user_project.send(awardable_string.to_sym).find(params[awardable_id_string.to_sym])
          award = awardable.award_emoji.find(params[:award_id])

          unauthorized! unless award.user == current_user || current_user.admin?

          award.destroy
          present award, with: Entities::AwardEmoji
        end
      end
    end
    helpers do
      def awardable_read_ability_name(awardable)
        "read_#{awardable.class.to_s.underscore.downcase}".to_sym
      end
    end
  end
end
