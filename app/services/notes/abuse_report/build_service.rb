# frozen_string_literal: true

module Notes
  module AbuseReport
    class BuildService < ::Notes::BuildService
      extend ::Gitlab::Utils::Override

      def initialize(user = nil, params = {})
        @current_user = user
        @params = params.dup
      end

      private

      override :handle_external_author
      def handle_external_author; end

      override :handle_confidentiality_params
      def handle_confidentiality_params; end

      override :new_note
      def new_note(params, _discussion)
        AntiAbuse::Reports::Note.new(params.merge(author: current_user))
      end

      override :find_discussion
      def find_discussion(discussion_id)
        AntiAbuse::Reports::Note.find_discussion(discussion_id)
      end

      override :discussion_not_found
      def discussion_not_found
        note = AntiAbuse::Reports::Note.new
        note.errors.add(:base, _('Discussion to reply to cannot be found'))
        note
      end
    end
  end
end
