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
      builds_without_retry.each do |build|
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
      running_or_pending = statuses.latest.running_or_pending
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
      statuses.pluck(:ref).compact.uniq
    end

    def statuses_for_ref(ref = nil)
      if ref
        statuses.for_ref(ref)
      else
        statuses
      end
    end

    def builds_without_retry(ref = nil)
      if ref
        builds.for_ref(ref).latest
      else
        builds.latest
      end
    end

    def retried
      @retried ||= (statuses.order(id: :desc) - statuses.latest)
    end

    def status(ref = nil)
      if yaml_errors.present?
        return 'failed'
      end

      latest_statuses = statuses.latest.to_a
      latest_statuses.reject! { |status| status.try(&:allow_failure?) }
      latest_statuses.select! { |status| status.ref.nil? || status.ref == ref } if ref

      if latest_statuses.none?
        return 'skipped'
      elsif latest_statuses.all?(&:success?)
        'success'
      elsif latest_statuses.all?(&:pending?)
        'pending'
      elsif latest_statuses.any?(&:running?) || latest_statuses.any?(&:pending?)
        'running'
      elsif latest_statuses.all?(&:canceled?)
        'canceled'
      else
        'failed'
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

    def duration(ref = nil)
      statuses_for_ref(ref).latest.select(&:duration).sum(&:duration).to_i
    end

    def finished_at
      @finished_at ||= statuses.order('finished_at DESC').first.try(:finished_at)
    end

    def coverage
      if project.coverage_enabled?
        coverage_array = builds_without_retry.map(&:coverage).compact
        if coverage_array.size >= 1
          '%.2f' % (coverage_array.reduce(:+) / coverage_array.size)
        end
      end
    end

    def matrix?(ref)
      builds_without_retry(ref).pluck(:id).size > 1
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
