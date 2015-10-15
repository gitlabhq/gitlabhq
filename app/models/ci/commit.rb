# == Schema Information
#
# Table name: commits
#
#  id           :integer          not null, primary key
#  project_id   :integer
#  ref          :string(255)
#  sha          :string(255)
#  before_sha   :string(255)
#  push_data    :text
#  created_at   :datetime
#  updated_at   :datetime
#  tag          :boolean          default(FALSE)
#  yaml_errors  :text
#  committed_at :datetime
#

module Ci
  class Commit < ActiveRecord::Base
    extend Ci::Model

    belongs_to :gl_project, class_name: '::Project', foreign_key: :gl_project_id
    has_many :statuses, dependent: :destroy, class_name: 'CommitStatus'
    has_many :builds, class_name: 'Ci::Build'
    has_many :trigger_requests, dependent: :destroy, class_name: 'Ci::TriggerRequest'

    validates_presence_of :sha
    validate :valid_commit_sha

    def self.truncate_sha(sha)
      sha[0...8]
    end

    def to_param
      sha
    end

    def project
      @project ||= gl_project.ensure_gitlab_ci_project
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
      if self.sha == Ci::Git::BLANK_SHA
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
      @commit ||= gl_project.commit(sha)
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
        CreateBuildsService.new.execute(self, stage, ref, tag, user, trigger_request).present?
      end
    end

    def create_next_builds(ref, tag, user, trigger_request)
      return unless config_processor

      stages = builds.where(ref: ref, tag: tag, trigger_request: trigger_request).group_by(&:stage)

      config_processor.stages.any? do |stage|
        unless stages.include?(stage)
          CreateBuildsService.new.execute(self, stage, ref, tag, user, trigger_request).present?
        end
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

      @status ||= begin
        latest = latest_statuses
        latest.reject! { |status| status.try(&:allow_failure?) }

        if latest.none?
          'skipped'
        elsif latest.all?(&:success?)
          'success'
        elsif latest.all?(&:pending?)
          'pending'
        elsif latest.any?(&:running?) || latest.any?(&:pending?)
          'running'
        elsif latest.all?(&:canceled?)
          'canceled'
        else
          'failed'
        end
      end
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

    def duration
      duration_array = latest_statuses.map(&:duration).compact
      duration_array.reduce(:+).to_i
    end

    def finished_at
      @finished_at ||= statuses.order('finished_at DESC').first.try(:finished_at)
    end

    def coverage
      if project.coverage_enabled?
        coverage_array = latest_builds.map(&:coverage).compact
        if coverage_array.size >= 1
          '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
        end
      end
    end

    def matrix_for_ref?(ref)
      latest_builds_for_ref(ref).size > 1
    end

    def config_processor
      @config_processor ||= Ci::GitlabCiYamlProcessor.new(ci_yaml_file)
    rescue Ci::GitlabCiYamlProcessor::ValidationError => e
      save_yaml_error(e.message)
      nil
    rescue Exception => e
      logger.error e.message + "\n" + e.backtrace.join("\n")
      save_yaml_error("Undefined yaml error")
      nil
    end

    def ci_yaml_file
      gl_project.repository.blob_at(sha, '.gitlab-ci.yml').data
    rescue
      nil
    end

    def skip_ci?
      git_commit_message =~ /(\[ci skip\])/ if git_commit_message
    end

    def update_committed!
      update!(committed_at: DateTime.now)
    end

    def should_create_next_builds?(build)
      # don't create other builds if this one is retried
      other_builds = builds.similar(build).latest
      return false unless other_builds.include?(build)

      other_builds.all? do |build|
        build.success? || build.ignored?
      end
    end

    private

    def save_yaml_error(error)
      return if self.yaml_errors?
      self.yaml_errors = error
      save
    end
  end
end
