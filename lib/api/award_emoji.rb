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
        boundary_type = awardable_params[:resource].to_s.singularize.to_sym

        params do
          requires :id, types: [String, Integer], desc: "The ID or URL-encoded path of the #{awardable_params[:resource] == :projects ? 'project' : 'group'}"
          requires :"#{awardable_id_string}", type: Integer, desc: Helpers::AwardEmoji.awardable_id_desc
        end

        [
          ":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
          ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"
        ].each do |endpoint|
          is_note_endpoint = endpoint.include?(':note_id')
          permission_suffix = is_note_endpoint ? "#{awardable_params[:type]}_note_award_emoji" : "#{awardable_params[:type]}_award_emoji"
          awardable_name = awardable_params[:type].humanize(capitalize: false)
          awardable_article = awardable_name.match?(/\A[aeiou]/i) ? 'an' : 'a'

          desc "List all emoji reactions for " \
            "#{awardable_article} #{awardable_name}#{' comment' if is_note_endpoint}" do
            detail "Lists all emoji reactions for a specified " \
              "#{is_note_endpoint ? "comment on #{awardable_article} #{awardable_name}" : awardable_name}. " \
              "This endpoint can be accessed without authentication if the " \
              "#{is_note_endpoint ? 'comment' : awardable_name} is publicly accessible."
            success Entities::AwardEmoji
            failure [{ code: 404, message: 'Not Found' }]
            is_array true
            tags AWARD_EMOJI_TAG
          end
          params do
            use :pagination
          end
          route_setting :authorization, permissions: :"read_#{permission_suffix}", boundary_type: boundary_type
          get endpoint, feature_category: awardable_params[:feature_category] do
            if can_read_awardable?
              awards = awardable.award_emoji
              # Batch load custom emoji URLs
              awards.each(&:url)
              present paginate(awards), with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          desc "Retrieve an emoji reaction from " \
            "#{awardable_article} #{awardable_name}#{' comment' if is_note_endpoint}" do
            detail "Retrieves a specified emoji reaction from " \
              "#{'a comment on ' if is_note_endpoint}#{awardable_article} #{awardable_name}. This endpoint " \
              "can be accessed without authentication if the " \
              "#{is_note_endpoint ? 'comment' : awardable_name} is publicly accessible."
            success Entities::AwardEmoji
            failure [{ code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :award_id, type: Integer, desc: 'ID of the emoji reaction.'
          end
          route_setting :authorization, permissions: :"read_#{permission_suffix}", boundary_type: boundary_type
          get "#{endpoint}/:award_id", feature_category: awardable_params[:feature_category] do
            if can_read_awardable?
              present awardable.award_emoji.find(params[:award_id]), with: Entities::AwardEmoji
            else
              not_found!("Award Emoji")
            end
          end

          desc "Add an emoji reaction to " \
            "#{awardable_article} #{awardable_name}#{' comment' if is_note_endpoint}" do
            detail "Adds an emoji reaction to " \
              "#{'a comment on ' if is_note_endpoint}#{awardable_article} #{awardable_name}."
            success Entities::AwardEmoji
            failure [{ code: 400, message: 'Bad Request' }, { code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :name, type: String, desc: 'Name of the emoji without colons.'
          end
          route_setting :authorization, permissions: :"create_#{permission_suffix}", boundary_type: boundary_type
          post endpoint, feature_category: awardable_params[:feature_category] do
            not_found!('Award Emoji') unless can_read_awardable? && can_award_awardable?

            service = AwardEmojis::AddService.new(awardable, params[:name], current_user).execute

            if service[:status] == :success
              present service[:award], with: Entities::AwardEmoji
            else
              not_found!("Award Emoji #{service[:message]}")
            end
          end

          desc "Delete an emoji reaction from " \
            "#{awardable_article} #{awardable_name}#{' comment' if is_note_endpoint}" do
            detail "Deletes a specified emoji reaction from " \
              "#{'a comment on ' if is_note_endpoint}#{awardable_article} #{awardable_name}. Only an " \
              "administrator or the user who added the reaction can delete it."
            success code: 204
            failure [{ code: 401, message: 'Unauthorized' }, { code: 404, message: 'Not Found' }]
            tags AWARD_EMOJI_TAG
          end
          params do
            requires :award_id, type: Integer, desc: 'ID of an emoji reaction.'
          end
          route_setting :authorization, permissions: :"delete_#{permission_suffix}", boundary_type: boundary_type
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

API::AwardEmoji.prepend_mod_with('API::AwardEmoji')
