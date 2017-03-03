module API
  module V3
    class AwardEmoji < Grape::API
      include PaginationParams

      before { authenticate! }
      AWARDABLES = %w[issue merge_request snippet].freeze

      resource :projects do
        AWARDABLES.each do |awardable_type|
          awardable_string = awardable_type.pluralize
          awardable_id_string = "#{awardable_type}_id"

          params do
            requires :id, type: String, desc: 'The ID of a project'
            requires :"#{awardable_id_string}", type: Integer, desc: "The ID of an Issue, Merge Request or Snippet"
          end

          [":id/#{awardable_string}/:#{awardable_id_string}/award_emoji",
           ":id/#{awardable_string}/:#{awardable_id_string}/notes/:note_id/award_emoji"].each do |endpoint|
            desc 'Delete a +awardables+ award emoji' do
              detail 'This feature was introduced in 8.9'
              success ::API::Entities::AwardEmoji
            end
            params do
              requires :award_id, type: Integer, desc: 'The ID of an award emoji'
            end
            delete "#{endpoint}/:award_id" do
              award = awardable.award_emoji.find(params[:award_id])

              unauthorized! unless award.user == current_user || current_user.admin?

              present award.destroy, with: ::API::Entities::AwardEmoji
            end
          end
        end
      end

      helpers do
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
      end
    end
  end
end
