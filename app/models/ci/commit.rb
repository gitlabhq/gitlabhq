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

    belongs_to :project, class_name: '::Project', foreign_key: :gl_project_id
    has_many :statuses, class_name: 'CommitStatus'
    has_many :builds, class_name: 'Ci::Build'
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest'

    scope :ordered, -> { order('CASE WHEN ci_commits.committed_at IS NULL THEN 0 ELSE 1 END', :committed_at, :id) }

    validates_presence_of :sha
    validate :valid_commit_sha

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def to_param
      sha
    end

    def project_id
      project.id
    end

    def last_build
      builds.order(:id).last
    end

    def retry
      latest_builds.each do |build|
        Ci::Build.retry(build)
      end
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

    def stage
      running_or_pending = statuses.latest.running_or_pending.ordered
      running_or_pending.first.try(:stage)
    end

    def create_builds(ref, tag, user, trigger_request = nil)
      return unless config_processor
      config_processor.stages.any? do |stage|
        CreateBuildsService.new.execute(self, stage, ref, tag, user, trigger_request, 'success').present?
      end
    end

    def create_next_builds(build)
      return unless config_processor

      # don't create other builds if this one is retried
      latest_builds = builds.similar(build).latest
      return unless latest_builds.exists?(build.id)

      # get list of stages after this build
      next_stages = config_processor.stages.drop_while { |stage| stage != build.stage }
      next_stages.delete(build.stage)

      # get status for all prior builds
      prior_builds = latest_builds.reject { |other_build| next_stages.include?(other_build.stage) }
      status = Ci::Status.get_status(prior_builds)

      # create builds for next stages based
      next_stages.any? do |stage|
        CreateBuildsService.new.execute(self, stage, build.ref, build.tag, build.user, build.trigger_request, status).present?
      end
    end

    def refs
      statuses.order(:ref).pluck(:ref).uniq
    end

    def latest_statuses
      @latest_statuses ||= statuses.latest.to_a
    end

    def latest_builds
      @latest_builds ||= builds.latest.to_a
    end

    def latest_builds_for_ref(ref)
      latest_builds.select { |build| build.ref == ref }
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - statuses.latest)
    end

    def status
      if yaml_errors.present?
        return 'failed'
      end

      @status ||= Ci::Status.get_status(latest_statuses)
    end

    def pending?
      status == 'pending'
    end

    def running?
      status == 'running'
    end

    def success?
      status == 'success'
    end

    def failed?
      status == 'failed'
    end

    def canceled?
      status == 'canceled'
    end

    def active?
      running? || pending?
    end

    def complete?
      canceled? || success? || failed?
    end

    def duration
      duration_array = latest_statuses.map(&:duration).compact
      duration_array.reduce(:+).to_i
    end

    def started_at
      @started_at ||= statuses.order('started_at ASC').first.try(:started_at)
    end

    def finished_at
      @finished_at ||= statuses.order('finished_at DESC').first.try(:finished_at)
    end

    def coverage
      coverage_array = latest_builds.map(&:coverage).compact
      if coverage_array.size >= 1
        '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
      end
    end

    def matrix_for_ref?(ref)
      latest_builds_for_ref(ref).size > 1
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

    def update_committed!
      update!(committed_at: DateTime.now)
    end

    private

    def save_yaml_error(error)
      return if self.yaml_errors?
      self.yaml_errors = error
      save
    end
  end
end
