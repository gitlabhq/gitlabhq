# frozen_string_literal: true

module Gitlab
  module Repositories
    module Mirror
      class BranchSkipFilter
        def initialize(project)
          @project = project
        end

        def skip_branch?(name)
          skip_unprotected_branch?(name) || skip_mismatched_branch?(name)
        end

        private

        attr_reader :project

        def skip_unprotected_branch?(name)
          project.only_mirror_protected_branches && !ProtectedBranch.protected?(project, name)
        end

        def skip_mismatched_branch?(name)
          project.mirror_branch_regex.present? && !branch_regex.match?(name)
        end

        def branch_regex
          @branch_regex ||= Gitlab::UntrustedRegexp.new(project.mirror_branch_regex)
        end
      end
    end
  end
end
