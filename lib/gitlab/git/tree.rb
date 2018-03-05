# Gitaly note: JV: needs 1 RPC, migration is in progress.

module Gitlab
  module Git
    class Tree
      include Gitlab::EncodingHelper

      attr_accessor :id, :root_id, :name, :path, :flat_path, :type,
        :mode, :commit_id, :submodule_url

      class << self
        # Get list of tree objects
        # for repository based on commit sha and path
        # Uses rugged for raw objects
        #
        # Gitaly migration: https://gitlab.com/gitlab-org/gitaly/issues/320
        def where(repository, sha, path = nil, recursive = false)
          path = nil if path == '' || path == '/'

          Gitlab::GitalyClient.migrate(:tree_entries) do |is_enabled|
            if is_enabled
              repository.gitaly_commit_client.tree_entries(repository, sha, path, recursive)
            else
              tree_entries_from_rugged(repository, sha, path, recursive)
            end
          end
        end

        private

        # Recursive search of tree id for path
        #
        # Ex.
        #   blog/            # oid: 1a
        #     app/           # oid: 2a
        #       models/      # oid: 3a
        #       views/       # oid: 4a
        #
        #
        # Tree.find_id_by_path(repo, '1a', 'app/models') # => '3a'
        #
        def find_id_by_path(repository, root_id, path)
          root_tree = repository.lookup(root_id)
          path_arr = path.split('/')

          entry = root_tree.find do |entry|
            entry[:name] == path_arr[0] && entry[:type] == :tree
          end

          return nil unless entry

          if path_arr.size > 1
            path_arr.shift
            find_id_by_path(repository, entry[:oid], path_arr.join('/'))
          else
            entry[:oid]
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
            new(
              id: entry[:oid],
              root_id: root_tree.oid,
              name: entry[:name],
              type: entry[:type],
              mode: entry[:filemode].to_s(8),
              path: path ? File.join(path, entry[:name]) : entry[:name],
              commit_id: sha
            )
          end
        rescue Rugged::ReferenceError
          []
        end
      end

      def initialize(options)
        %w(id root_id name path flat_path type mode commit_id).each do |key|
          self.send("#{key}=", options[key.to_sym]) # rubocop:disable GitlabSecurity/PublicSend
        end
      end

      def name
        encode! @name
      end

      def path
        encode! @path
      end

      def flat_path
        encode! @flat_path
      end

      def dir?
        type == :tree
      end

      def file?
        type == :blob
      end

      def submodule?
        type == :commit
      end

      def readme?
        name =~ /^readme/i
      end

      def contributing?
        name =~ /^contributing/i
      end
    end
  end
end
