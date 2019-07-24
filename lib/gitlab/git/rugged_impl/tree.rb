# frozen_string_literal: true

# NOTE: This code is legacy. Do not add/modify code here unless you have
# discussed with the Gitaly team.  See
# https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code
# for more details.

module Gitlab
  module Git
    module RuggedImpl
      module Tree
        module ClassMethods
          extend ::Gitlab::Utils::Override
          include Gitlab::Git::RuggedImpl::UseRugged

          override :tree_entries
          def tree_entries(repository, sha, path, recursive)
            if use_rugged?(repository, :rugged_tree_entries)
              execute_rugged_call(:tree_entries_with_flat_path_from_rugged, repository, sha, path, recursive)
            else
              super
            end
          end

          def tree_entries_with_flat_path_from_rugged(repository, sha, path, recursive)
            tree_entries_from_rugged(repository, sha, path, recursive).tap do |entries|
              # This was an optimization to reduce N+1 queries for Gitaly
              # (https://gitlab.com/gitlab-org/gitaly/issues/530).  It
              # used to be done lazily in the view via
              # TreeHelper#flatten_tree, so it's possible there's a
              # performance impact by loading this eagerly.
              rugged_populate_flat_path(repository, sha, path, entries)
            end
          end

          def tree_entries_from_rugged(repository, sha, path, recursive)
            current_path_entries = get_tree_entries_from_rugged(repository, sha, path)
            ordered_entries = []

            current_path_entries.each do |entry|
              ordered_entries << entry

              if recursive && entry.dir?
                ordered_entries.concat(tree_entries_from_rugged(repository, sha, entry.path, true))
              end
            end

            ordered_entries
          end

          def rugged_populate_flat_path(repository, sha, path, entries)
            entries.each do |entry|
              entry.flat_path = entry.path

              next unless entry.dir?

              entry.flat_path =
                if path
                  File.join(path, rugged_flatten_tree(repository, sha, entry, path))
                else
                  rugged_flatten_tree(repository, sha, entry, path)
                end
            end
          end

          # Returns the relative path of the first subdir that doesn't have only one directory descendant
          def rugged_flatten_tree(repository, sha, tree, root_path)
            subtree = tree_entries_from_rugged(repository, sha, tree.path, false)

            if subtree.count == 1 && subtree.first.dir?
              File.join(tree.name, rugged_flatten_tree(repository, sha, subtree.first, root_path))
            else
              tree.name
            end
          end

          def get_tree_entries_from_rugged(repository, sha, path)
            commit = repository.lookup(sha)
            root_tree = commit.tree

            tree = if path
                     id = find_id_by_path(repository, root_tree.oid, path)
                     if id
                       repository.lookup(id)
                     else
                       []
                     end
                   else
                     root_tree
                   end

            tree.map do |entry|
              current_path = path ? File.join(path, entry[:name]) : entry[:name]

              new(
                id: entry[:oid],
                root_id: root_tree.oid,
                name: entry[:name],
                type: entry[:type],
                mode: entry[:filemode].to_s(8),
                path: current_path,
                commit_id: sha
              )
            end
          rescue Rugged::ReferenceError
            []
          end
        end
      end
    end
  end
end
