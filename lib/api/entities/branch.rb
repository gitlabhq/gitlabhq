# frozen_string_literal: true

module API
  module Entities
    class Branch < Grape::Entity
      include Gitlab::Routing

      expose :name

      expose :commit, using: Entities::Commit do |repo_branch, options|
        options[:project].repository.commit(repo_branch.dereferenced_target)
      end

      expose :merged do |repo_branch, options|
        if options[:merged_branch_names]
          options[:merged_branch_names].include?(repo_branch.name)
        else
          options[:project].repository.merged_to_root_ref?(repo_branch)
        end
      end

      expose :protected do |repo_branch, options|
        ::ProtectedBranch.protected?(options[:project], repo_branch.name)
      end

      expose :developers_can_push do |repo_branch, options|
        ::ProtectedBranch.developers_can?(:push, repo_branch.name, protected_refs: options[:project].protected_branches)
      end

      expose :developers_can_merge do |repo_branch, options|
        ::ProtectedBranch.developers_can?(:merge, repo_branch.name, protected_refs: options[:project].protected_branches)
      end

      expose :can_push do |repo_branch, options|
        Gitlab::UserAccess.new(options[:current_user], project: options[:project]).can_push_to_branch?(repo_branch.name)
      end

      expose :default do |repo_branch, options|
        options[:project].default_branch == repo_branch.name
      end

      expose :web_url do |repo_branch|
        project_tree_url(options[:project], repo_branch.name)
      end
    end
  end
end
