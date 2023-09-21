# frozen_string_literal: true

require_relative '../../qa_helpers'

module RuboCop
  module Cop
    module QA
      # This cop checks for the usages of API fabrications and suggests using
      # the corresponding QA factories instead.
      # @example
      #   Good:
      #     create(:project)
      #   Bad:
      #     Resource::Project.fabricate_via_api!
      # @example
      #   Good:
      #     create(:group)
      #   Bad:
      #     Resource::Group.fabricate_via_api!
      # @example
      #   Good:
      #     create(:user, username: 'username', password: 'password')
      #   Bad:
      #     Resource::User.fabricate_via_api! do |user|
      #       user.username = 'username'
      #       user.password = 'password'
      #     end
      class FabricateUsage < RuboCop::Cop::Base
        MESSAGE = "Prefer create(:%{factory}[, ...]) here."
        RESOURCES_TO_CHECK = {
          'Resource::Project' => :project,
          'Resource::Group' => :group,
          'Resource::Issue' => :issue,
          'Resource::User' => :user,
          'Resource::Pipeline' => :pipeline,
          'Resource::Job' => :job,
          'Resource::File' => :file,
          'Resource::GroupAccessToken' => :group_access_token,
          'Resource::ProjectAccessToken' => :project_access_token,
          'Resource::GroupLabel' => :group_label,
          'Resource::ProjectLabel' => :project_label,
          'Resource::GroupRunner' => :group_runner,
          'Resource::ProjectRunner' => :project_runner,
          'Resource::GroupMilestone' => :group_milestone,
          'Resource::ProjectMilestone' => :project_milestone,
          'Resource::Snippet' => :snippet,
          'Resource::ProjectSnippet' => :project_snippet
        }.freeze

        RESTRICT_ON_SEND = %i[fabricate_via_api!].freeze

        def_node_matcher :const_receiver, <<~PATTERN
          (send $const ...)
        PATTERN

        def on_send(node)
          factory = RESOURCES_TO_CHECK[const_receiver(node)&.const_name]
          return unless factory

          add_offense(node, message: format(MESSAGE, factory: factory))
        end
      end
    end
  end
end
