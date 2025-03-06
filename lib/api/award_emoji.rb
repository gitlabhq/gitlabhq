# frozen_string_literal: true

module API
  class AwardEmoji < ::API::Base
    include PaginationParams

    helpers ::API::Helpers::AwardEmoji

    AWARD_EMOJI_TAG = %w[award_emoji].freeze

    Helpers::AwardEmoji.awardables.each do |awardable_params|
      resource awardable_params[:resource], requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
        awardable_string = awardable_params[:type].pluralize
        awardable_id_string = "#{awardable_params[:type]}_#{awardable_params[:find_by]}"

        params do
          requires :id, types: [String, Integer], desc: "The ID or URL-encoded path of the #{awardable_params[:resource] == :projects ? 'project' : 'group'}"
          requires :"#{awardable_id_string}", type: Integer, desc: Helpers::AwardEmoji.awardable_id_desc
        end

        [
          ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
          ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"
        ].each do |endpoint|
          desc "List an awardable's emoji reactions for #{awardable_params[:resource]}" do
            detail 'Get a list of all emoji reactions for a specified awardable. This feature was introduced in 8.9'
            success Entities::AwardEmoji
            failure [{ code: 404, message: 'Not Found' }]
            is_array true
            tags AWARD_EMOJI_TAG
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

          desc 'Get a single emoji reaction' do
            detail 'Get a single emoji reaction from an issue, snippet, or merge request. This feature was introduced in 8.9'
            success Entities::AwardEmoji
            failure [{ code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :award_id, type: Integer, desc: 'ID of the emoji reaction.'
          end
          get "#{endpoint}/:award_id", feature_category: awardable_params[:feature_category] do
            if can_read_awardable?
              present awardable.award_emoji.find(params[:award_id]), with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          desc 'Add a new emoji reaction' do
            detail 'Add an emoji reaction on the specified awardable. This feature was introduced in 8.9'
            success Entities::AwardEmoji
            failure [{ code: 400, message: 'Bad Request' }, { code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :name, type: String, desc: 'Name of the emoji without colons.'
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

          desc 'Delete an emoji reaction' do
            detail 'Only an administrator or the author of the reaction can delete an emoji reaction. This feature was introduced in 8.9'
            success code: 204
            failure [{ code: 401, message: 'Unauthorized' }, { code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :award_id, type: Integer, desc: 'ID of an emoji reaction.'
          end
          delete "#{endpoint}/:award_id", feature_category: awardable_params[:feature_category] do
            award = awardable.award_emoji.find(params[:award_id])

            unauthorized! unless award.user == current_user || current_user&.can_admin_all_resources?

            destroy_conditionally!(award) do
              AwardEmojis::DestroyService.new(awardable, award.name, award.user).execute
            end
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
          awardable.issuable_ability_name
        when Snippet, ProjectSnippet
          :read_snippet
        else
          :"read_#{awardable.class.to_s.underscore}"
        end
      end
    end
  end
end
