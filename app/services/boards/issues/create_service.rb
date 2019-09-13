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
        ::Issues::CreateService.new(project, current_user, params).execute
      end
    end
  end
end

Boards::Issues::CreateService.prepend_if_ee('EE::Boards::Issues::CreateService')
