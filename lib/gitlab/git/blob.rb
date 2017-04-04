module Gitlab
  module Git
    class Blob
      include Linguist::BlobHelper
      include Gitlab::Git::EncodingHelper

      # This number is the maximum amount of data that we want to display to
      # the user. We load as much as we can for encoding detection
      # (Linguist) and LFS pointer parsing. All other cases where we need full
      # blob data should use load_all_data!.
      MAX_DATA_DISPLAY_SIZE = 10485760

      attr_accessor :name, :path, :size, :data, :mode, :id, :commit_id, :loaded_size, :binary

      class << self
        def find(repository, sha, path)
          commit = repository.lookup(sha)
          root_tree = commit.tree

          blob_entry = find_entry_by_path(repository, root_tree.oid, path)

          return nil unless blob_entry

          if blob_entry[:type] == :commit
            submodule_blob(blob_entry, path, sha)
          else
            blob = repository.lookup(blob_entry[:oid])

            if blob
              new(
                id: blob.oid,
                name: blob_entry[:name],
                size: blob.size,
                data: blob.content(MAX_DATA_DISPLAY_SIZE),
                mode: blob_entry[:filemode].to_s(8),
                path: path,
                commit_id: sha,
                binary: blob.binary?
              )
            end
          end
        end

        def raw(repository, sha)
          blob = repository.lookup(sha)

          new(
            id: blob.oid,
            size: blob.size,
            data: blob.content(MAX_DATA_DISPLAY_SIZE),
            binary: blob.binary?
          )
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
        # Blob.find_entry_by_path(repo, '1a', 'app/file.rb') # => '4a'
        #
        def find_entry_by_path(repository, root_id, path)
          root_tree = repository.lookup(root_id)
          # Strip leading slashes
          path[/^\/*/] = ''
          path_arr = path.split('/')

          entry = root_tree.find do |entry|
            entry[:name] == path_arr[0]
          end

          return nil unless entry

          if path_arr.size > 1
            return nil unless entry[:type] == :tree
            path_arr.shift
            find_entry_by_path(repository, entry[:oid], path_arr.join('/'))
          else
            [:blob, :commit].include?(entry[:type]) ? entry : nil
          end
        end

        def submodule_blob(blob_entry, path, sha)
          new(
            id: blob_entry[:oid],
            name: blob_entry[:name],
            data: '',
            path: path,
            commit_id: sha,
          )
        end
      end

      def initialize(options)
        %w(id name path size data mode commit_id binary).each do |key|
          self.send("#{key}=", options[key.to_sym])
        end

        @loaded_all_data = false
        # Retain the actual size before it is encoded
        @loaded_size = @data.bytesize if @data
      end

      def binary?
        @binary.nil? ? super : @binary == true
      end

      def empty?
        !data || data == ''
      end

      def data
        encode! @data
      end

      # Load all blob data (not just the first MAX_DATA_DISPLAY_SIZE bytes) into
      # memory as a Ruby string.
      def load_all_data!(repository)
        return if @data == '' # don't mess with submodule blobs
        return @data if @loaded_all_data

        @loaded_all_data = true
        @data = repository.lookup(id).content
        @loaded_size = @data.bytesize
      end

      def name
        encode! @name
      end

      # Valid LFS object pointer is a text file consisting of
      # version
      # oid
      # size
      # see https://github.com/github/git-lfs/blob/v1.1.0/docs/spec.md#the-pointer
      def lfs_pointer?
        has_lfs_version_key? && lfs_oid.present? && lfs_size.present?
      end

      def lfs_oid
        if has_lfs_version_key?
          oid = data.match(/(?<=sha256:)([0-9a-f]{64})/)
          return oid[1] if oid
        end

        nil
      end

      def lfs_size
        if has_lfs_version_key?
          size = data.match(/(?<=size )([0-9]+)/)
          return size[1] if size
        end

        nil
      end

      def truncated?
        size && (size > loaded_size)
      end

      private

      def has_lfs_version_key?
        !empty? && text? && data.start_with?("version https://git-lfs.github.com/spec")
      end
    end
  end
end
