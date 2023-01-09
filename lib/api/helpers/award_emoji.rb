# frozen_string_literal: true

module API
  module Helpers
    module AwardEmoji
      def self.awardables
        [
          { type: 'issue', resource: :projects, find_by: :iid, feature_category: :team_planning },
          { type: 'merge_request', resource: :projects, find_by: :iid, feature_category: :code_review_workflow },
          { type: 'snippet', resource: :projects, find_by: :id, feature_category: :source_code_management }
        ]
      end

      def self.awardable_id_desc
        "The ID of an Issue, Merge Request or Snippet"
      end

      # rubocop: disable CodeReuse/ActiveRecord
      def awardable
        @awardable ||=
          if params.include?(:note_id)
            note_id = params.delete(:note_id)

            awardable.notes.find(note_id)
          elsif params.include?(:issue_iid)
            user_project.issues.find_by!(iid: params[:issue_iid])
          elsif params.include?(:merge_request_iid)
            user_project.merge_requests.find_by!(iid: params[:merge_request_iid])
          elsif params.include?(:snippet_id)
            user_project.snippets.find(params[:snippet_id])
          end
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end

API::Helpers::AwardEmoji.prepend_mod_with('API::Helpers::AwardEmoji')
