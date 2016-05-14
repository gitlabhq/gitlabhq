module Ci
  class Commit < ActiveRecord::Base
    extend Ci::Model
    include Statuseable

    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
    has_many :statuses, class_name: 'CommitStatus'
    has_many :builds, class_name: 'Ci::Build'
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest'

    validates_presence_of :sha
    validates_presence_of :status
    validate :valid_commit_sha

    # Invalidate object and save if when touched
    after_touch :update_state

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def self.stages
      # We use pluck here due to problems with MySQL which doesn't allow LIMIT/OFFSET in queries
      CommitStatus.where(commit: pluck(:id)).stages
    end

    def project_id
      project.id
    end

    def valid_commit_sha
      if self.sha == Gitlab::Git::BLANK_SHA
        self.errors.add(:sha, " cant be 00000000 (branch removal)")
      end
    end

    def git_author_name
      commit_data.author_name if commit_data
    end

    def git_author_email
      commit_data.author_email if commit_data
    end

    def git_commit_message
      commit_data.message if commit_data
    end

    def short_sha
      Ci::Commit.truncate_sha(sha)
    end

    def commit_data
      @commit ||= project.commit(sha)
    rescue
      nil
    end

    def branch?
      !tag?
    end

    def retryable?
      builds.latest.any? do |build|
        build.failed? && build.retryable?
      end
    end

    def cancel_running
      builds.running_or_pending.each(&:cancel)
    end

    def retry_failed
      builds.latest.failed.select(&:retryable?).each(&:retry)
    end

    def latest?
      return false unless ref
      commit = project.commit(ref)
      return false unless commit
      commit.sha == sha
    end

    def triggered?
      trigger_requests.any?
    end

    def create_builds(user, trigger_request = nil)
      return unless config_processor
      config_processor.stages.any? do |stage|
        CreateBuildsService.new(self).execute(stage, user, 'success', trigger_request).present?
      end
    end

    def create_next_builds(build)
      return unless config_processor

      # don't create other builds if this one is retried
      latest_builds = builds.latest
      return unless latest_builds.exists?(build.id)

      # get list of stages after this build
      next_stages = config_processor.stages.drop_while { |stage| stage != build.stage }
      next_stages.delete(build.stage)

      # get status for all prior builds
      prior_builds = latest_builds.where.not(stage: next_stages)
      prior_status = prior_builds.status

      # create builds for next stages based
      next_stages.any? do |stage|
        CreateBuildsService.new(self).execute(stage, build.user, prior_status, build.trigger_request).present?
      end
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - statuses.latest)
    end

    def coverage
      coverage_array = statuses.latest.map(&:coverage).compact
      if coverage_array.size >= 1
        '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
      end
    end

    def config_processor
      return nil unless ci_yaml_file
      return @config_processor if defined?(@config_processor)

      @config_processor ||= begin
        Ci::GitlabCiYamlProcessor.new(ci_yaml_file, project.path_with_namespace)
      rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
        save_yaml_error(e.message)
        nil
      rescue
        save_yaml_error("Undefined error")
        nil
      end
    end

    def ci_yaml_file
      return @ci_yaml_file if defined?(@ci_yaml_file)

      @ci_yaml_file ||= begin
        blob = project.repository.blob_at(sha, '.gitlab-ci.yml')
        blob.load_all_data!(project.repository)
        blob.data
      rescue
        nil
      end
    end

    def skip_ci?
      git_commit_message =~ /(\[ci skip\])/ if git_commit_message
    end

    private

    def update_state
      statuses.reload
      self.status = if yaml_errors.blank?
                      statuses.latest.status || 'skipped'
                    else
                      'failed'
                    end
      self.started_at = statuses.started_at
      self.finished_at = statuses.finished_at
      self.duration = statuses.latest.duration
      save
    end

    def save_yaml_error(error)
      return if self.yaml_errors?
      self.yaml_errors = error
      update_state
    end
  end
end
