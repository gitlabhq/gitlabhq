# frozen_string_literal: true

module API
  class AwardEmoji < ::API::Base
    include PaginationParams

    helpers ::API::Helpers::AwardEmoji

    before { authenticate! }

    Helpers::AwardEmoji.awardables.each do |awardable_params|
      resource awardable_params[:resource], requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        awardable_string = awardable_params[:type].pluralize
        awardable_id_string = "#{awardable_params[:type]}_#{awardable_params[:find_by]}"

        params do
          requires :id, type: String, desc: "The ID of a #{awardable_params[:resource] == :projects ? 'project' : 'group'}"
          requires :"#{awardable_id_string}", type: Integer, desc: Helpers::AwardEmoji.awardable_id_desc
        end

        [
          ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
          ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"
        ].each do |endpoint|
          desc 'Get a list of project +awardable+ award emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          params do
            use :pagination
          end
          get endpoint, feature_category: awardable_params[:feature_category] do
            if can_read_awardable?
              awards = awardable.award_emoji
              present paginate(awards), with: Entities::AwardEmoji
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
          get "#{endpoint}/:award_id", feature_category: awardable_params[:feature_category] do
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
          post endpoint, feature_category: awardable_params[:feature_category] do
            not_found!('Award Emoji') unless can_read_awardable? && can_award_awardable?

            service = AwardEmojis::AddService.new(awardable, params[:name], current_user).execute

            if service[:status] == :success
              present service[:award], with: Entities::AwardEmoji
            else
              not_found!("Award Emoji #{service[:message]}")
            end
          end

          desc 'Delete a +awardables+ award emoji' do
            detail 'This feature was introduced in 8.9'
            success Entities::AwardEmoji
          end
          params do
            requires :award_id, type: Integer, desc: 'The ID of an award emoji'
          end
          delete "#{endpoint}/:award_id", feature_category: awardable_params[:feature_category] do
            award = awardable.award_emoji.find(params[:award_id])

            unauthorized! unless award.user == current_user || current_user.admin?

            destroy_conditionally!(award)
          end
        end
      end
    end

    helpers do
      def can_read_awardable?
        can?(current_user, read_ability(awardable), awardable)
      end

      def can_award_awardable?
        awardable.user_can_award?(current_user)
      end

      def read_ability(awardable)
        case awardable
        when Note
          read_ability(awardable.noteable)
        when Snippet, ProjectSnippet
          :read_snippet
        else
          :"read_#{awardable.class.to_s.underscore}"
        end
      end
    end
  end
end
