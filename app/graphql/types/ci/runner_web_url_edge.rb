# frozen_string_literal: true

module Types
  module Ci
    class RunnerWebUrlEdge < ::Types::BaseEdge
      field :edit_url, GraphQL::Types::String, null: true,
        description: 'Web URL of the runner edit page. The value depends on where you put the field in the query. ' \
          'You can use it for projects or groups.',
        extras: [:parent]
      field :web_url, GraphQL::Types::String, null: true,
        description: 'Web URL of the runner. The value depends on where you put the field in the query. ' \
          'You can use it for projects or groups.',
        extras: [:parent]

      def initialize(node, connection)
        super

        @runner = node.node
      end

      # here parent is a Keyset::Connection
      def edit_url(parent:)
        runner_url(owner: parent.parent, url_type: :edit_url)
      end

      def web_url(parent:)
        runner_url(owner: parent.parent, url_type: :default)
      end

      private

      def runner_url(owner:, url_type: :default)
        case owner
        when ::Group
          return Gitlab::Routing.url_helpers.edit_group_runner_url(owner, @runner) if url_type == :edit_url

          Gitlab::Routing.url_helpers.group_runner_url(owner, @runner)
        when ::Project
          return Gitlab::Routing.url_helpers.edit_project_runner_url(owner, @runner) if url_type == :edit_url

          Gitlab::Routing.url_helpers.project_runner_url(owner, @runner)
        end
      end
    end
  end
end
