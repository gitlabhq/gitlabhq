# frozen_string_literal: true

module Boards
  module Issues
    class CreateService < Boards::BaseService
      attr_accessor :project

      def initialize(parent, project, user, params = {})
        @project = project

        super(parent, user, params)
      end

      def execute
        create_issue(params.merge(issue_params))
      end

      private

      def issue_params
        { label_ids: [list.label_id] }
      end

      def board
        @board ||= parent.boards.find(params.delete(:board_id))
      end

      def list
        @list ||= board.lists.find(params.delete(:list_id))
      end

      def create_issue(params)
        # NOTE: We are intentionally not doing a spam/CAPTCHA check for issues created via boards.
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/29400#note_598479184 for more context.
        ::Issues::CreateService.new(container: project, current_user: current_user, params: params, perform_spam_check: false).execute
      end
    end
  end
end

Boards::Issues::CreateService.prepend_mod_with('Boards::Issues::CreateService')
