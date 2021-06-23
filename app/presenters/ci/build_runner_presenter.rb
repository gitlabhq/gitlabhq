# frozen_string_literal: true

module Ci
  class BuildRunnerPresenter < SimpleDelegator
    include Gitlab::Utils::StrongMemoize

    RUNNER_REMOTE_TAG_PREFIX = 'refs/tags/'
    RUNNER_REMOTE_BRANCH_PREFIX = 'refs/remotes/origin/'

    def artifacts
      return unless options[:artifacts]

      list = []
      list << create_archive(options[:artifacts])
      list << create_reports(options[:artifacts][:reports], expire_in: options[:artifacts][:expire_in])
      list.flatten.compact
    end

    def ref_type
      if tag
        'tag'
      else
        'branch'
      end
    end

    def git_depth
      if git_depth_variable
        git_depth_variable[:value]
      else
        project.ci_default_git_depth
      end.to_i
    end

    def runner_variables
      if Feature.enabled?(:variable_inside_variable, project)
        variables.sort_and_expand_all(project, keep_undefined: true).to_runner_variables
      else
        variables.to_runner_variables
      end
    end

    def refspecs
      specs = []
      specs << refspec_for_persistent_ref if persistent_ref_exist?

      if git_depth > 0
        specs << refspec_for_branch(ref) if branch? || legacy_detached_merge_request_pipeline?
        specs << refspec_for_tag(ref) if tag?
      else
        specs << refspec_for_branch
        specs << refspec_for_tag
      end

      specs
    end

    # rubocop: disable CodeReuse/ActiveRecord
    def all_dependencies
      dependencies = super

      if Feature.enabled?(:preload_associations_jobs_request_api_endpoint, project, default_enabled: :yaml)
        ActiveRecord::Associations::Preloader.new.preload(dependencies, :job_artifacts_archive)
      end

      dependencies
    end
    # rubocop: enable CodeReuse/ActiveRecord

    private

    def create_archive(artifacts)
      return unless artifacts[:untracked] || artifacts[:paths]

      archive = {
        artifact_type: :archive,
        artifact_format: :zip,
        name: artifacts[:name],
        untracked: artifacts[:untracked],
        paths: artifacts[:paths],
        when: artifacts[:when],
        expire_in: artifacts[:expire_in]
      }

      if artifacts.dig(:exclude).present?
        archive.merge(exclude: artifacts[:exclude])
      else
        archive
      end
    end

    def create_reports(reports, expire_in:)
      return unless reports&.any?

      reports.map do |report_type, report_paths|
        {
          artifact_type: report_type.to_sym,
          artifact_format: ::Ci::JobArtifact::TYPE_AND_FORMAT_PAIRS.fetch(report_type.to_sym),
          name: ::Ci::JobArtifact::DEFAULT_FILE_NAMES.fetch(report_type.to_sym),
          paths: report_paths,
          when: 'always',
          expire_in: expire_in
        }
      end
    end

    def refspec_for_branch(ref = '*')
      "+#{Gitlab::Git::BRANCH_REF_PREFIX}#{ref}:#{RUNNER_REMOTE_BRANCH_PREFIX}#{ref}"
    end

    def refspec_for_tag(ref = '*')
      "+#{Gitlab::Git::TAG_REF_PREFIX}#{ref}:#{RUNNER_REMOTE_TAG_PREFIX}#{ref}"
    end

    def refspec_for_persistent_ref
      # Use persistent_ref.sha because it sometimes causes 'git fetch' to do
      # less work. See
      # https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/746.
      "+#{pipeline.persistent_ref.sha}:#{pipeline.persistent_ref.path}"
    end

    def persistent_ref_exist?
      ##
      # Persistent refs for pipelines definitely exist from GitLab 12.4,
      # hence, we don't need to check the ref existence before passing it to runners.
      # Checking refs pressurizes gitaly node and should be avoided.
      # Issue: https://gitlab.com/gitlab-com/gl-infra/production/-/issues/2143
      return true if Feature.enabled?(:ci_skip_persistent_ref_existence_check)

      pipeline.persistent_ref.exist?
    end

    def git_depth_variable
      strong_memoize(:git_depth_variable) do
        variables&.find { |variable| variable[:key] == 'GIT_DEPTH' }
      end
    end
  end
end

Ci::BuildRunnerPresenter.prepend_mod_with('Ci::BuildRunnerPresenter')
