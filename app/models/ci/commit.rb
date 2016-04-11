# == Schema Information
#
# Table name: ci_commits
#
#  id            :integer          not null, primary key
#  project_id    :integer
#  ref           :string(255)
#  sha           :string(255)
#  before_sha    :string(255)
#  push_data     :text
#  created_at    :datetime
#  updated_at    :datetime
#  tag           :boolean          default(FALSE)
#  yaml_errors   :text
#  committed_at  :datetime
#  gl_project_id :integer
#

module Ci
  class Commit < ActiveRecord::Base
    extend Ci::Model
    include CiStatus

    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
    has_many :statuses, class_name: 'CommitStatus'
    has_many :builds, class_name: 'Ci::Build'
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest'

    validates_presence_of :sha
    validate :valid_commit_sha

    # Make sure that status is saved
    before_save :status
    before_save :started_at
    before_save :finished_at
    before_save :duration

    # Invalidate object and save if when touched
    after_touch :reload
    after_touch :invalidate
    after_touch :save

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def stages
      statuses.group(:stage).order(:stage_idx).pluck(:stage)
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
        build.failed? || build.retryable?
      end
    end

    def invalidate
      write_attribute(:status, nil)
      write_attribute(:started_at, nil)
      write_attribute(:finished_at, nil)
      write_attribute(:duration, nil)
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
      prior_builds = latest_builds.reject { |other_build| next_stages.include?(other_build.stage) }
      status = Ci::Status.get_status(prior_builds)

      # create builds for next stages based
      next_stages.any? do |stage|
        CreateBuildsService.new(self).execute(stage, build.user, status, build.trigger_request).present?
      end
    end

    def latest
      statuses.latest
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - statuses.latest)
    end

    def status
      read_attribute(:status) || update_status
    end

    def duration
      read_attribute(:duration) || update_duration
    end

    def started_at
      read_attribute(:started_at) || update_started_at
    end

    def finished_at
      read_attribute(:finished_at) || update_finished_at
    end

    def coverage
      coverage_array = latest.map(&:coverage).compact
      if coverage_array.size >= 1
        '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
      end
    end

    def config_processor
      return nil unless ci_yaml_file
      @config_processor ||= Ci::GitlabCiYamlProcessor.new(ci_yaml_file, project.path_with_namespace)
    rescue Ci::GitlabCiYamlProcessor::ValidationError, Psych::SyntaxError => e
      save_yaml_error(e.message)
      nil
    rescue
      save_yaml_error("Undefined error")
      nil
    end

    def ci_yaml_file
      return nil if defined?(@ci_yaml_file)
      @ci_yaml_file ||= begin
        blob = project.repository.blob_at(sha, '.gitlab-ci.yml')
        blob.load_all_data!(project.repository)
        blob.data
      end
    rescue
      nil
    end

    def skip_ci?
      git_commit_message =~ /(\[ci skip\])/ if git_commit_message
    end

    private

    def update_status
      status =
        if yaml_errors.present?
          'failed'
        else
          latest.status || 'skipped'
        end
    end

    def update_started_at
      started_at =
        statuses.minimum(:started_at)
    end

    def update_finished_at
      finished_at =
        statuses.maximum(:finished_at)
    end

    def update_duration
      duration = begin
        duration_array = latest.map(&:duration).compact
        duration_array.reduce(:+).to_i
      end
    end

    def update_statuses
      update_status
      update_started_at
      update_finished_at
      update_duration
      save
    end

    def save_yaml_error(error)
      return if self.yaml_errors?
      self.yaml_errors = error
      update_status
      save
    end
  end
end
