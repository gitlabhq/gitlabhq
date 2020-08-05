# frozen_string_literal: true

# NOTE: This code is legacy. Do not add/modify code here unless you have
# discussed with the Gitaly team.  See
# https://docs.gitlab.com/ee/development/gitaly.html#legacy-rugged-code
# for more details.

module Gitlab
  module Git
    module RuggedImpl
      module Blob
        module ClassMethods
          extend ::Gitlab::Utils::Override
          include Gitlab::Git::RuggedImpl::UseRugged

          override :tree_entry
          def tree_entry(repository, sha, path, limit)
            if use_rugged?(repository, :rugged_tree_entry)
              execute_rugged_call(:rugged_tree_entry, repository, sha, path, limit)
            else
              super
            end
          end

          private

          def rugged_tree_entry(repository, sha, path, limit)
            return unless path

            # Strip any leading / characters from the path
            path = path.sub(%r{\A/*}, '')

            rugged_commit = repository.lookup(sha)
            root_tree = rugged_commit.tree

            blob_entry = find_entry_by_path(repository, root_tree.oid, *path.split('/'))

            return unless blob_entry

            if blob_entry[:type] == :commit
              submodule_blob(blob_entry, path, sha)
            else
              blob = repository.lookup(blob_entry[:oid])

              if blob
                new(
                  id: blob.oid,
                  name: blob_entry[:name],
                  size: blob.size,
                  # Rugged::Blob#content is expensive; don't call it if we don't have to.
                  data: limit == 0 ? '' : blob.content(limit),
                  mode: blob_entry[:filemode].to_s(8),
                  path: path,
                  commit_id: sha,
                  binary: blob.binary?
                )
              end
            end
          rescue Rugged::ReferenceError
            nil
          end

          # Recursive search of blob id by path
          #
          # Ex.
          #   blog/            # oid: 1a
          #     app/           # oid: 2a
          #       models/      # oid: 3a
          #       file.rb      # oid: 4a
          #
          #
          # Blob.find_entry_by_path(repo, '1a', 'blog', 'app', 'file.rb') # => '4a'
          #
          def find_entry_by_path(repository, root_id, *path_parts)
            root_tree = repository.lookup(root_id)

            entry = root_tree.find do |entry|
              entry[:name] == path_parts[0]
            end

            return unless entry

            if path_parts.size > 1
              return unless entry[:type] == :tree

              path_parts.shift
              find_entry_by_path(repository, entry[:oid], *path_parts)
            else
              [:blob, :commit].include?(entry[:type]) ? entry : nil
            end
          end

          def submodule_blob(blob_entry, path, sha)
            new(
              id: blob_entry[:oid],
              name: blob_entry[:name],
              size: 0,
              data: '',
              path: path,
              commit_id: sha
            )
          end
        end
      end
    end
  end
end
