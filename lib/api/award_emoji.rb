module API
  class AwardEmoji < Grape::API
    before { authenticate! }
    AWARDABLES = %w[issue merge_request snippet]

    resource :projects do
      AWARDABLES.each do |awardable_type|
        awardable_string = awardable_type.pluralize
        awardable_id_string = "#{awardable_type}_id"

        params do
          requires :id, type: String, desc: 'The ID of a project'
          requires :"#{awardable_id_string}", type: Integer, desc: "The ID of an Issue, Merge Request or Snippet"
        end

        [ ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
          ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"
        ].each do |endpoint|

          desc 'Get a list of project +awardable+ award emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          get endpoint do
            if can_read_awardable?
              awards = paginate(awardable.award_emoji)
              present awards, with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          desc 'Get a specific award emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          params do
            requires :award_id, type: Integer, desc: 'The ID of the award'
          end
          get "#{endpoint}/:award_id" do
            if can_read_awardable?
              present awardable.award_emoji.find(params[:award_id]), with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          desc 'Award a new Emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          params do
            requires :name, type: String, desc: 'The name of a award_emoji (without colons)'
          end
          post endpoint do
            not_found!('Award Emoji') unless can_read_awardable? && can_award_awardable?

            award = awardable.create_award_emoji(params[:name], current_user)

            if award.persisted?
              present award, with: Entities::AwardEmoji
            else
              not_found!("Award Emoji #{award.errors.messages}")
            end
          end

          desc 'Delete a +awardables+ award emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          params do
            requires :award_id, type: Integer, desc: 'The ID of an award emoji'
          end
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
        can?(current_user, read_ability(awardable), awardable)
      end

      def can_award_awardable?
        awardable.user_can_award?(current_user, params[:name])
      end

      def awardable
        @awardable ||=
          begin
            if params.include?(:note_id)
              note_id = params.delete(:note_id)

              awardable.notes.find(note_id)
            elsif params.include?(:issue_id)
              user_project.issues.find(params[:issue_id])
            elsif params.include?(:merge_request_id)
              user_project.merge_requests.find(params[:merge_request_id])
            else
              user_project.snippets.find(params[:snippet_id])
            end
          end
      end

      def read_ability(awardable)
        case awardable
        when Note
          read_ability(awardable.noteable)
        else
          :"read_#{awardable.class.to_s.underscore}"
        end
      end
    end
  end
end
