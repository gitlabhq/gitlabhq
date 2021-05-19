# frozen_string_literal: true

module Packages
  module Go
    class VersionFinder
      include Gitlab::Golang

      attr_reader :mod

      def initialize(mod)
        @mod = mod
      end

      def execute
        @mod.project.repository.tags
          .filter { |tag| semver_tag? tag }
          .map    { |tag| @mod.version_by(ref: tag) }
          .filter { |ver| ver.valid? }
      end

      def find(target)
        case target
        when String
          if pseudo_version? target
            semver = parse_semver(target)
            version = parse_pseudo_version(semver)
            commit = validate_pseudo_version(@mod.project, version)
            Packages::Go::ModuleVersion.new(@mod, :pseudo, commit, name: target, semver: semver)
          else
            @mod.version_by(ref: target)
          end

        when Gitlab::Git::Ref
          @mod.version_by(ref: target)

        when ::Commit, Gitlab::Git::Commit
          @mod.version_by(commit: target)

        else
          raise ArgumentError, 'not a valid target'
        end
      end
    end
  end
end
