# frozen_string_literal: true

module Gitlab
  module Diff
    module FileCollection
      class WikiPage < Base
        def initialize(page, diff_options:)
          commit = page.wiki.commit(page.version.commit)
          diff_options = diff_options.merge(
            expanded: true,
            paths: [page.path]
          )

          super(commit,
            # TODO: Uncouple diffing from projects
            # https://gitlab.com/gitlab-org/gitlab/-/issues/217752
            project: page.wiki,
            diff_options: diff_options,
            diff_refs: commit.diff_refs)
        end
      end
    end
  end
end
