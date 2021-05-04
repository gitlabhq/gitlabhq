# frozen_string_literal: true

module Packages
  module Go
    class ModuleVersion
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Golang

      VALID_TYPES = %i[ref commit pseudo].freeze

      attr_reader :mod, :type, :ref, :commit

      delegate :major, to: :@semver, allow_nil: true
      delegate :minor, to: :@semver, allow_nil: true
      delegate :patch, to: :@semver, allow_nil: true
      delegate :prerelease, to: :@semver, allow_nil: true
      delegate :build, to: :@semver, allow_nil: true

      def initialize(mod, type, commit, name: nil, semver: nil, ref: nil)
        raise ArgumentError, "invalid type '#{type}'" unless VALID_TYPES.include? type
        raise ArgumentError, "mod is required" unless mod
        raise ArgumentError, "commit is required" unless commit

        if type == :ref
          raise ArgumentError, "ref is required" unless ref
        elsif type == :pseudo
          raise ArgumentError, "name is required" unless name
          raise ArgumentError, "semver is required" unless semver
        end

        @mod = mod
        @type = type
        @commit = commit
        @name = name if name
        @semver = semver if semver
        @ref = ref if ref
      end

      def name
        @name || @ref&.name
      end

      def full_name
        "#{mod.name}@#{name || commit.sha}"
      end

      def gomod
        strong_memoize(:gomod) do
          if strong_memoized?(:blobs)
            blob_at(@mod.path + '/go.mod')
          elsif @mod.path.empty?
            @mod.project.repository.blob_at(@commit.sha, 'go.mod')&.data
          else
            @mod.project.repository.blob_at(@commit.sha, @mod.path + '/go.mod')&.data
          end
        end
      end

      def archive
        suffix_len = @mod.path == '' ? 0 : @mod.path.length + 1

        Zip::OutputStream.write_buffer do |zip|
          files.each do |file|
            zip.put_next_entry "#{full_name}/#{file[suffix_len...]}"
            zip.write blob_at(file)
          end
        end
      end

      def files
        strong_memoize(:files) do
          ls_tree.filter { |e| !excluded.any? { |n| e.start_with? n } }
        end
      end

      def excluded
        strong_memoize(:excluded) do
          ls_tree
            .filter { |f| f.end_with?('/go.mod') && f != @mod.path + '/go.mod' }
            .map    { |f| f[0..-7] }
        end
      end

      def valid?
        # assume the module version is valid if a corresponding Package exists
        return true if ::Packages::Go::PackageFinder.new(mod.project, mod.name, name).exists?

        @mod.path_valid?(major) && @mod.gomod_valid?(gomod)
      end

      private

      def blob_at(path)
        return if path.nil? || path.empty?

        path = path[1..] if path.start_with? '/'

        blobs.find { |x| x.path == path }&.data
      end

      def blobs
        strong_memoize(:blobs) { @mod.project.repository.batch_blobs(files.map { |x| [@commit.sha, x] }) }
      end

      def ls_tree
        strong_memoize(:ls_tree) do
          path =
            if @mod.path.empty?
              '.'
            else
              @mod.path
            end

          @mod.project.repository.gitaly_repository_client.search_files_by_name(@commit.sha, path)
        end
      end
    end
  end
end
