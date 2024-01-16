# frozen_string_literal: true

module Gitlab
  module Git
    class Tree
      include Gitlab::EncodingHelper
      extend Gitlab::Git::WrapsGitalyErrors

      attr_accessor :id, :type, :mode, :commit_id, :submodule_url, :ref_type
      attr_writer :name, :path, :flat_path

      class << self
        # Get list of tree objects
        # for repository based on commit sha and path
        def tree_entries(
          repository:,
          sha:,
          path: nil,
          recursive: false,
          skip_flat_paths: true,
          rescue_not_found:  true,
          pagination_params: nil
        )
          path = nil if path == '' || path == '/'

          wrapped_gitaly_errors do
            repository.gitaly_commit_client.tree_entries(
              repository, sha, path, recursive, skip_flat_paths, pagination_params)
          end

        # Incorrect revision or path could lead to index error.
        # We silently handle such errors by returning an empty set of entries and cursor
        # unless the parameter rescue_not_found is set to false.
        rescue Gitlab::Git::Index::IndexError => e
          return [[], nil] if rescue_not_found

          raise e
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

          return unless entry

          if path_arr.size > 1
            path_arr.shift
            find_id_by_path(repository, entry[:oid], path_arr.join('/'))
          else
            entry[:oid]
          end
        end
      end

      def initialize(options)
        %w[id name path flat_path type mode commit_id].each do |key|
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
