# frozen_string_literal: true

require 'securerandom'

module QA
  module Resource
    class ProtectedBranch < Base
      attr_accessor :branch_name,
                    :allowed_to_push,
                    :allowed_to_merge,
                    :new_branch,
                    :require_code_owner_approval

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'protected-branch-project'
          resource.initialize_with_readme = true
        end
      end

      attribute :branch do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = branch_name
          commit.start_branch = project.default_branch
          commit.commit_message = 'Add new file'
          commit.add_files([
            { file_path: "new_file-#{SecureRandom.hex(8)}.md", content: 'new file' }
          ])
        end
      end

      def initialize
        @new_branch = true
        @branch_name = 'test/branch'
        @allowed_to_push = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @allowed_to_merge = {
          roles: Resource::ProtectedBranch::Roles::DEVS_AND_MAINTAINERS
        }
        @require_code_owner_approval = false
      end

      def fabricate!
        populate_new_branch_if_required

        project.visit!
        Page::Project::Menu.perform(&:go_to_repository_settings)

        Page::Project::Settings::Repository.perform do |setting|
          setting.expand_protected_branches do |page|
            if new_branch
              page.select_branch(branch_name)
              page.select_allowed_to_merge(allowed_to_merge)
              page.select_allowed_to_push(allowed_to_push)
              page.protect_branch
            else
              page.require_code_owner_approval(branch_name) if require_code_owner_approval
            end
          end
        end
      end

      def fabricate_via_api!
        populate_new_branch_if_required

        super
      end

      def self.unprotect_via_api!(&block)
        self.remove_via_api!(&block)
      end

      def api_get_path
        "/projects/#{project.id}/protected_branches/#{branch_name}"
      end

      def api_delete_path
        "/projects/#{project.id}/protected_branches/#{branch_name}"
      end

      def api_post_path
        "/projects/#{project.id}/protected_branches"
      end

      def api_post_body
        {
          name: branch_name,
          code_owner_approval_required: require_code_owner_approval
        }
        .merge(allowed_to_push_hash)
        .merge(allowed_to_merge_hash)
      end

      def allowed_to_push_hash
        allowed = {}
        allowed.merge({ push_access_level: allowed_to_push[:roles][:access_level] }) if allowed_to_push.key?(:roles)
      end

      def allowed_to_merge_hash
        allowed = {}
        allowed.merge({ merge_access_level: allowed_to_merge[:roles][:access_level] }) if allowed_to_merge.key?(:roles)
      end

      def resource_web_url(resource)
        super
      rescue ResourceURLMissingError
        # this particular resource does not expose a web_url property
      end

      class Roles
        NO_ONE = { description: 'No one', access_level: 0 }.freeze
        DEVS_AND_MAINTAINERS = { description: 'Developers + Maintainers', access_level: 30 }.freeze
        MAINTAINERS = { description: 'Maintainers', access_level: 40 }.freeze
      end

      private

      def populate_new_branch_if_required
        return unless new_branch

        populate(:branch)

        project.wait_for_push_new_branch(branch_name)
      end
    end
  end
end
