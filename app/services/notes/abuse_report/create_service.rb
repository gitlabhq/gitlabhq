# frozen_string_literal: true

module Notes
  module AbuseReport
    class CreateService < ::Notes::CreateService
      def initialize(user = nil, params = {})
        @current_user = user
        @params = params.dup
      end

      private

      def build_note(_executing_user)
        Notes::AbuseReport::BuildService.new(current_user, params).execute
      end

      def after_commit(note)
        note.run_after_commit do
          # TODO: enqueue creation of todos, NewNoteWorker or similar (create a new one)
          # https://gitlab.com/gitlab-org/gitlab/-/issues/477320
        end
      end

      def quick_actions_supported?(_note)
        false
      end

      def check_for_spam?(_only_commands)
        false
      end

      def when_saved(note, _additional_params)
        # add todos and events tracking
        # https://gitlab.com/gitlab-org/gitlab/-/issues/477320
        # https://gitlab.com/gitlab-org/gitlab/-/issues/477322
      end
    end
  end
end
