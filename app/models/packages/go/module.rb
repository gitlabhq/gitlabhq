# frozen_string_literal: true

module Packages
  module Go
    class Module
      include Gitlab::Utils::StrongMemoize

      attr_reader :project, :name, :path

      def initialize(project, name, path)
        @project = project
        @name = name
        @path = path
      end

      def versions
        Packages::Go::VersionFinder.new(self).execute
      end
      strong_memoize_attr :versions

      def version_by(ref: nil, commit: nil)
        raise ArgumentError, 'no filter specified' unless ref || commit
        raise ArgumentError, 'ref and commit are mutually exclusive' if ref && commit

        if commit
          return version_by_sha(commit) if commit.is_a? String

          return version_by_commit(commit)
        end

        return version_by_name(ref) if ref.is_a? String

        version_by_ref(ref)
      end

      def path_valid?(major)
        m = %r{/v(\d+)$}i.match(@name)

        case major
        when 0, 1
          m.nil?
        else
          !m.nil? && m[1].to_i == major
        end
      end

      def gomod_valid?(gomod)
        if Feature.enabled?(:go_proxy_disable_gomod_validation, @project)
          return gomod&.start_with?("module ")
        end

        gomod&.split("\n", 2)&.first == "module #{@name}"
      end

      private

      def version_by_name(name)
        # avoid a Gitaly call if possible
        if strong_memoized?(:versions)
          v = versions.find { |v| v.name == ref }
          return v if v
        end

        ref = @project.repository.find_tag(name) || @project.repository.find_branch(name)
        return unless ref

        version_by_ref(ref)
      end

      def version_by_ref(ref)
        # reuse existing versions
        if strong_memoized?(:versions)
          v = versions.find { |v| v.ref == ref }
          return v if v
        end

        commit = ref.dereferenced_target
        semver = Packages::SemVer.parse(ref.name, prefixed: true)
        Packages::Go::ModuleVersion.new(self, :ref, commit, ref: ref, semver: semver)
      end

      def version_by_sha(sha)
        commit = @project.commit_by(oid: sha)
        return unless ref

        version_by_commit(commit)
      end

      def version_by_commit(commit)
        Packages::Go::ModuleVersion.new(self, :commit, commit)
      end
    end
  end
end
