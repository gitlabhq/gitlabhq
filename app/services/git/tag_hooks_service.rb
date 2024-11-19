# frozen_string_literal: true

module Git
  class TagHooksService < ::Git::BaseHooksService
    private

    alias_method :removing_tag?, :removing_ref?

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
        project.commit(tag.dereferenced_target) if tag
      end
    end
  end
end

Git::TagHooksService.prepend_mod_with('Git::TagHooksService')
