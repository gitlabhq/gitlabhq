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
          'Resource::CiVariable' => :ci_variable,
          'Resource::Commit' => :commit,
          'Resource::Design' => :design,
          'Resource::File' => :file,
          'Resource::Group' => :group,
          'Resource::GroupAccessToken' => :group_access_token,
          'Resource::GroupDeployToken' => :group_deploy_token,
          'Resource::GroupLabel' => :group_label,
          'Resource::GroupMilestone' => :group_milestone,
          'Resource::GroupRunner' => :group_runner,
          'Resource::GroupWikiPage' => :group_wiki_page,
          'Resource::Issue' => :issue,
          'Resource::Job' => :job,
          'Resource::MergeRequest' => :merge_request,
          'Resource::Package' => :package,
          'Resource::Pipeline' => :pipeline,
          'Resource::PipelineSchedule' => :pipeline_schedule,
          'Resource::Project' => :project,
          'Resource::ProjectAccessToken' => :project_access_token,
          'Resource::ProjectDeployToken' => :project_deploy_token,
          'Resource::ProjectLabel' => :project_label,
          'Resource::ProjectMilestone' => :project_milestone,
          'Resource::ProjectRunner' => :project_runner,
          'Resource::ProjectSnippet' => :project_snippet,
          'Resource::ProjectWikiPage' => :project_wiki_page,
          'Resource::Sandbox' => :sandbox,
          'Resource::Snippet' => :snippet,
          'Resource::Tag' => :tag,
          'Resource::User' => :user
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
