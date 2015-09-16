# == Schema Information
#
# Table name: builds
#
#  id                 :integer          not null, primary key
#  project_id         :integer
#  status             :string(255)
#  finished_at        :datetime
#  trace              :text
#  created_at         :datetime
#  updated_at         :datetime
#  started_at         :datetime
#  runner_id          :integer
#  commit_id          :integer
#  coverage           :float
#  commands           :text
#  job_id             :integer
#  name               :string(255)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  deploy             :boolean          default(FALSE)
#  trigger_request_id :integer
#

module Ci
  class Build < ActiveRecord::Base
    extend Ci::Model
    
    LAZY_ATTRIBUTES = ['trace']

    belongs_to :commit, class_name: 'Ci::Commit'
    belongs_to :project, class_name: 'Ci::Project'
    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :trigger_request, class_name: 'Ci::TriggerRequest'

    serialize :options

    validates :commit, presence: true
    validates :status, presence: true
    validates :coverage, numericality: true, allow_blank: true

    scope :running, ->() { where(status: "running") }
    scope :pending, ->() { where(status: "pending") }
    scope :success, ->() { where(status: "success") }
    scope :failed, ->() { where(status: "failed")  }
    scope :unstarted, ->() { where(runner_id: nil) }
    scope :running_or_pending, ->() { where(status:[:running, :pending]) }

    acts_as_taggable

    # To prevent db load megabytes of data from trace
    default_scope -> { select(Ci::Build.columns_without_lazy) }

    class << self
      def columns_without_lazy
        (column_names - LAZY_ATTRIBUTES).map do |column_name|
          "#{table_name}.#{column_name}"
        end
      end

      def last_month
        where('created_at > ?', Date.today - 1.month)
      end

      def first_pending
        pending.unstarted.order('created_at ASC').first
      end

      def create_from(build)
        new_build = build.dup
        new_build.status = :pending
        new_build.runner_id = nil
        new_build.save
      end

      def retry(build)
        new_build = Ci::Build.new(status: :pending)
        new_build.options = build.options
        new_build.commands = build.commands
        new_build.tag_list = build.tag_list
        new_build.commit_id = build.commit_id
        new_build.project_id = build.project_id
        new_build.name = build.name
        new_build.allow_failure = build.allow_failure
        new_build.stage = build.stage
        new_build.trigger_request = build.trigger_request
        new_build.save
        new_build
      end
    end

    state_machine :status, initial: :pending do
      event :run do
        transition pending: :running
      end

      event :drop do
        transition running: :failed
      end

      event :success do
        transition running: :success
      end

      event :cancel do
        transition [:pending, :running] => :canceled
      end

      after_transition pending: :running do |build, transition|
        build.update_attributes started_at: Time.now
      end

      after_transition any => [:success, :failed, :canceled] do |build, transition|
        build.update_attributes finished_at: Time.now
        project = build.project

        if project.web_hooks?
          Ci::WebHookService.new.build_end(build)
        end

        if build.commit.success?
          build.commit.create_next_builds(build.trigger_request)
        end

        project.execute_services(build)

        if project.coverage_enabled?
          build.update_coverage
        end
      end

      state :pending, value: 'pending'
      state :running, value: 'running'
      state :failed, value: 'failed'
      state :success, value: 'success'
      state :canceled, value: 'canceled'
    end

    delegate :sha, :short_sha, :before_sha, :ref,
      to: :commit, prefix: false

    def trace_html
      html = Ci::Ansi2html::convert(trace) if trace.present?
      html ||= ''
    end

    def trace
      if project && read_attribute(:trace).present?
        read_attribute(:trace).gsub(project.token, 'xxxxxx')
      end
    end

    def started?
      !pending? && !canceled? && started_at
    end

    def active?
      running? || pending?
    end

    def complete?
      canceled? || success? || failed?
    end

    def ignored?
      failed? && allow_failure?
    end

    def timeout
      project.timeout
    end

    def variables
      yaml_variables + project_variables + trigger_variables
    end

    def duration
      if started_at && finished_at
        finished_at - started_at
      elsif started_at
        Time.now - started_at
      end
    end

    def project
      commit.project
    end

    def project_id
      commit.project_id
    end

    def project_name
      project.name
    end

    def repo_url
      project.repo_url_with_auth
    end

    def allow_git_fetch
      project.allow_git_fetch
    end

    def update_coverage
      coverage = extract_coverage(trace, project.coverage_regex)

      if coverage.is_a? Numeric
        update_attributes(coverage: coverage)
      end
    end

    def extract_coverage(text, regex)
      begin
        matches = text.gsub(Regexp.new(regex)).to_a.last
        coverage = matches.gsub(/\d+(\.\d+)?/).first

        if coverage.present?
          coverage.to_f
        end
      rescue => ex
        # if bad regex or something goes wrong we dont want to interrupt transition
        # so we just silentrly ignore error for now
      end
    end

    def trace
      if File.exist?(path_to_trace)
        File.read(path_to_trace)
      else
        # backward compatibility
        read_attribute :trace
      end
    end

    def trace=(trace)
      unless Dir.exists? dir_to_trace
        FileUtils.mkdir_p dir_to_trace
      end

      File.write(path_to_trace, trace)
    end

    def dir_to_trace
      File.join(
        Settings.gitlab_ci.builds_path,
        created_at.utc.strftime("%Y_%m"),
        project.id.to_s
      )
    end

    def path_to_trace
      "#{dir_to_trace}/#{id}.log"
    end

    private

    def yaml_variables
      if commit.config_processor
        commit.config_processor.variables.map do |key, value|
          { key: key, value: value, public: true }
        end
      else
        []
      end
    end

    def project_variables
      project.variables.map do |variable|
        { key: variable.key, value: variable.value, public: false }
      end
    end

    def trigger_variables
      if trigger_request && trigger_request.variables
        trigger_request.variables.map do |key, value|
          { key: key, value: value, public: false }
        end
      else
        []
      end
    end
  end
end
