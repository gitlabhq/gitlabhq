module Gitlab
  module GitalyClient
    class Commit
      # The ID of empty tree.
      # See http://stackoverflow.com/a/40884093/1856239 and https://github.com/git/git/blob/3ad8b5bf26362ac67c9020bf8c30eee54a84f56d/cache.h#L1011-L1012
      EMPTY_TREE_ID = '4b825dc642cb6eb9a060e54bf8d69288fbee4904'.freeze

      class << self
        def diff_from_parent(commit, options = {})
          project   = commit.project
          channel   = GitalyClient.get_channel(project.repository_storage)
          stub      = Gitaly::Diff::Stub.new(nil, nil, channel_override: channel)
          repo      = Gitaly::Repository.new(path: project.repository.path_to_repo)
          parent    = commit.parents[0]
          parent_id = parent ? parent.id : EMPTY_TREE_ID
          request   = Gitaly::CommitDiffRequest.new(
            repository: repo,
            left_commit_id: parent_id,
            right_commit_id: commit.id
          )

          Gitlab::Git::DiffCollection.new(stub.commit_diff(request), options)
        end

        def is_ancestor(repository, ancestor_id, child_id)
          project = Project.find_by_path(repository.path)
          channel = GitalyClient.get_channel(project.repository_storage)
          stub = Gitaly::Commit::Stub.new(nil, nil, channel_override: channel)
          repo = Gitaly::Repository.new(path: repository.path_to_repo)
          request = Gitaly::CommitIsAncestorRequest.new(
            repository: repo,
            ancestor_id: ancestor_id,
            child_id: child_id
          )

          stub.commit_is_ancestor(request).value
        end
      end
    end
  end
end
