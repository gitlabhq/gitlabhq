# frozen_string_literal: true

module API
  class AwardEmoji < Grape::API
    include PaginationParams

    before { authenticate! }
    AWARDABLES = [
      { type: 'issue', find_by: :iid },
      { type: 'merge_request', find_by: :iid },
      { type: 'snippet', find_by: :id }
    ].freeze

    params do
      requires :id, type: String, desc: 'The ID of a project'
    end
    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      AWARDABLES.each do |awardable_params|
        awardable_string = awardable_params[:type].pluralize
        awardable_id_string = "#{awardable_params[:type]}_#{awardable_params[:find_by]}"

        params do
          requires :"#{awardable_id_string}", type: Integer, desc: "The ID of an Issue, Merge Request or Snippet"
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
          get endpoint do
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
          delete "#{endpoint}/:award_id" do
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

      # rubocop: disable CodeReuse/ActiveRecord
      def awardable
        @awardable ||=
          begin
            if params.include?(:note_id)
              note_id = params.delete(:note_id)

              awardable.notes.find(note_id)
            elsif params.include?(:issue_iid)
              user_project.issues.find_by!(iid: params[:issue_iid])
            elsif params.include?(:merge_request_iid)
              user_project.merge_requests.find_by!(iid: params[:merge_request_iid])
            else
              user_project.snippets.find(params[:snippet_id])
            end
          end
      end
      # rubocop: enable CodeReuse/ActiveRecord

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
