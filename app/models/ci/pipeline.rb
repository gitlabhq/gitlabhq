module Ci
  class Pipeline < ActiveRecord::Base
    extend Ci::Model
    include Statuseable

    self.table_name = 'ci_commits'

    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
    belongs_to :user

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id
    has_many :builds, class_name: 'Ci::Build', foreign_key: :commit_id
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest', foreign_key: :commit_id

    validates_presence_of :sha
    validates_presence_of :status
    validate :valid_commit_sha

    # Invalidate object and save if when touched
    after_touch :update_state
    after_save :keep_around_commits

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def self.stages
      # We use pluck here due to problems with MySQL which doesn't allow LIMIT/OFFSET in queries
      CommitStatus.where(pipeline: pluck(:id)).stages
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
      commit.try(:author_name)
    end

    def git_author_email
      commit.try(:author_email)
    end

    def git_commit_message
      commit.try(:message)
    end

    def git_commit_title
      commit.try(:title)
    end

    def short_sha
      Ci::Pipeline.truncate_sha(sha)
    end

    def commit
      @commit ||= project.commit(sha)
    rescue
      nil
    end

    def branch?
      !tag?
    end

    def manual_actions
      builds.latest.manual_actions
    end

    def retryable?
      builds.latest.any? do |build|
        build.failed? && build.retryable?
      end
    end

    def cancelable?
      builds.running_or_pending.any?
    end

    def cancel_running
      builds.running_or_pending.each(&:cancel)
    end

    def retry_failed(user)
      builds.latest.failed.select(&:retryable?).each do |build|
        Ci::Build.retry(build, user)
      end
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
      ##
      # We persist pipeline only if there are builds available
      #
      return unless config_processor

      build_builds_for_stages(config_processor.stages, user,
                              'success', trigger_request) && save
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

      # build builds for next stage that has builds available
      # and save pipeline if we have builds
      build_builds_for_stages(next_stages, build.user, prior_status,
                              build.trigger_request) && save
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
        self.yaml_errors = e.message
        nil
      rescue
        self.yaml_errors = 'Undefined error'
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
      git_commit_message =~ /\[(ci skip|skip ci)\]/i if git_commit_message
    end

    def environments
      builds.where.not(environment: nil).success.pluck(:environment).uniq
    end

    # Manually set the notes for a Ci::Pipeline
    # There is no ActiveRecord relation between Ci::Pipeline and notes
    # as they are related to a commit sha. This method helps importing
    # them using the +Gitlab::ImportExport::RelationFactory+ class.
    def notes=(notes)
      notes.each do |note|
        note[:id] = nil
        note[:commit_id] = sha
        note[:noteable_id] = self['id']
        note.save!
      end
    end

    def notes
      Note.for_commit_id(sha)
    end

    def predefined_variables
      [
        { key: 'CI_PIPELINE_ID', value: id.to_s, public: true }
      ]
    end

    private

    def build_builds_for_stages(stages, user, status, trigger_request)
      ##
      # Note that `Array#any?` implements a short circuit evaluation, so we
      # build builds only for the first stage that has builds available.
      #
      stages.any? do |stage|
        CreateBuildsService.new(self)
          .execute(stage, user, status, trigger_request).present?
      end
    end

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

    def keep_around_commits
      return unless project
      
      project.repository.keep_around(self.sha)
      project.repository.keep_around(self.before_sha)
    end
  end
end
