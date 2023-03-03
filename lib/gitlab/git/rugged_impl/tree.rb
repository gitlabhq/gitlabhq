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

          TREE_SORT_ORDER = { tree: 0, blob: 1, commit: 2 }.freeze

          override :tree_entries
          def tree_entries(repository, sha, path, recursive, skip_flat_paths, pagination_params = nil)
            if use_rugged?(repository, :rugged_tree_entries)
              entries = execute_rugged_call(
                :tree_entries_with_flat_path_from_rugged, repository, sha, path, recursive, skip_flat_paths)

              if pagination_params
                paginated_response(entries, pagination_params[:limit], pagination_params[:page_token].to_s)
              else
                [entries, nil]
              end
            else
              super
            end
          end

          # Rugged version of TreePagination in Go: https://gitlab.com/gitlab-org/gitaly/-/merge_requests/3611
          def paginated_response(entries, limit, token)
            total_entries = entries.count

            return [[], nil] if limit == 0 || limit.blank?

            entries = Gitlab::Utils.stable_sort_by(entries) { |x| TREE_SORT_ORDER[x.type] }

            if token.blank?
              index = 0
            else
              index = entries.index { |entry| entry.id == token }

              raise Gitlab::Git::CommandError, "could not find starting OID: #{token}" if index.nil?

              index += 1
            end

            return [entries[index..], nil] if limit < 0

            last_index = index + limit
            result = entries[index...last_index]

            if last_index < total_entries
              cursor = Gitaly::PaginationCursor.new(next_cursor: result.last.id)
            end

            [result, cursor]
          end

          def tree_entries_with_flat_path_from_rugged(repository, sha, path, recursive, skip_flat_paths)
            tree_entries_from_rugged(repository, sha, path, recursive).tap do |entries|
              # This was an optimization to reduce N+1 queries for Gitaly
              # (https://gitlab.com/gitlab-org/gitaly/issues/530).
              rugged_populate_flat_path(repository, sha, path, entries) unless skip_flat_paths
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
