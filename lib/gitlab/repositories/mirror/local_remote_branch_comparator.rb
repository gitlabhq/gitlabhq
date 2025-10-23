# frozen_string_literal: true

module Gitlab
  module Repositories
    module Mirror
      class LocalRemoteBranchComparator
        MAX_NUMBER_TO_PROCESS_SPECIFIC_REVISIONS = 100

        def initialize(project, branch_filter: nil)
          @project = project
          @branch_filter = branch_filter
        end

        # Returns an array of revision specifications for LFS processing
        # @return [Array<String>, nil] Array of revision specs or nil if no changes
        # Examples: ['abc123..def456', 'refs/remotes/upstream/new-branch'] or ['--all']
        def calculate_changed_revisions
          local_branches = get_local_branches
          return ['--all'] if local_branches.empty?

          changed_revisions = build_changed_revisions(local_branches)

          return if changed_revisions.empty?

          return ['--all'] if changed_revisions.size > MAX_NUMBER_TO_PROCESS_SPECIFIC_REVISIONS

          changed_revisions
        end

        private

        attr_reader :project, :branch_filter

        def build_changed_revisions(local_branches)
          get_remote_branches.filter_map do |name, remote_sha|
            next if should_skip_branch?(name)

            local_sha = local_branches[name]

            if local_sha.nil?
              "refs/remotes/upstream/#{name}"
            elsif local_sha != remote_sha
              "#{local_sha}..#{remote_sha}"
            end
          end
        end

        def map_branches_to_targets(branch_collection)
          branches = {}
          branch_collection.each do |branch|
            branches[branch.name.to_s] = branch.target
          end
          branches
        end

        def get_remote_branches
          # Not calling upstream_branches to avoid memoization overhead
          map_branches_to_targets(project.repository.remote_branches(::Repository::MIRROR_REMOTE))
        end

        def get_local_branches
          map_branches_to_targets(project.repository.branches)
        end

        def should_skip_branch?(branch_name)
          return false unless branch_filter

          branch_filter.skip_branch?(branch_name)
        end
      end
    end
  end
end
