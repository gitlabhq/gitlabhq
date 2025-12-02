# frozen_string_literal: true

module Git
  class TagHooksService < ::Git::BaseHooksService
    private

    alias_method :removing_tag?, :removing_ref?

    # If a tag does not have a dereferenced_target this means it's not
    # referencing a commit. This can happen when you create a tag for a tree or
    # blob object. We cannot run pipelines against trees and blobs so we skip
    # the creation.
    def create_pipeline?
      return super if Feature.enabled?(:bypass_tag_commit_check_during_tag_hooks, project)

      super && tag_commit.present?
    end

    def hook_name
      :tag_push_hooks
    end

    def limited_commits
      [tag_commit].compact
    end

    def commits_count
      limited_commits.count
    end

    def event_message
      tag&.message
    end

    def tag
      strong_memoize(:tag) do
        next if removing_tag?

        tag_name = Gitlab::Git.ref_name(ref)
        tag = project.repository.find_tag(tag_name)

        tag if tag && tag.target == newrev
      end
    end

    def tag_commit
      strong_memoize(:tag_commit) do
        project.commit(tag.dereferenced_target) if tag&.dereferenced_target
      end
    end
  end
end

Git::TagHooksService.prepend_mod_with('Git::TagHooksService')
