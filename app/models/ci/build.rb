# == Schema Information
#
# Table name: ci_builds
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
#  coverage           :float
#  commit_id          :integer
#  commands           :text
#  job_id             :integer
#  name               :string(255)
#  deploy             :boolean          default(FALSE)
#  options            :text
#  allow_failure      :boolean          default(FALSE), not null
#  stage              :string(255)
#  trigger_request_id :integer
#  stage_idx          :integer
#  tag                :boolean
#  ref                :string(255)
#  user_id            :integer
#  type               :string(255)
#  target_url         :string(255)
#  description        :string(255)
#  artifacts_file     :text
#

module Ci
  class Build < CommitStatus
    LAZY_ATTRIBUTES = ['trace']

    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :trigger_request, class_name: 'Ci::TriggerRequest'

    serialize :options

    validates :coverage, numericality: true, allow_blank: true
    validates_presence_of :ref

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :similar, ->(build) { where(ref: build.ref, tag: build.tag, trigger_request_id: build.trigger_request_id) }

    mount_uploader :artifacts_file, ArtifactUploader

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
        new_build.status = 'pending'
        new_build.runner_id = nil
        new_build.trigger_request_id = nil
        new_build.save
      end

      def retry(build)
        new_build = Ci::Build.new(status: 'pending')
        new_build.ref = build.ref
        new_build.tag = build.tag
        new_build.options = build.options
        new_build.commands = build.commands
        new_build.tag_list = build.tag_list
        new_build.commit_id = build.commit_id
        new_build.name = build.name
        new_build.allow_failure = build.allow_failure
        new_build.stage = build.stage
        new_build.stage_idx = build.stage_idx
        new_build.trigger_request = build.trigger_request
        new_build.save
        new_build
      end
    end

    state_machine :status, initial: :pending do
      after_transition any => [:success, :failed, :canceled] do |build, transition|
        project = build.project

        if project.web_hooks?
          Ci::WebHookService.new.build_end(build)
        end

        build.commit.create_next_builds(build)
        project.execute_services(build)

        if project.coverage_enabled?
          build.update_coverage
        end
      end
    end

    def ignored?
      failed? && allow_failure?
    end

    def retryable?
      commands.present?
    end

    def retried?
      !self.commit.latest_builds_for_ref(self.ref).include?(self)
    end

    def trace_html
      html = Ci::Ansi2html::convert(trace) if trace.present?
      html || ''
    end

    def timeout
      project.timeout
    end

    def variables
      predefined_variables + yaml_variables + project_variables + trigger_variables
    end

    def project
      commit.project
    end

    def project_id
      commit.project.id
    end

    def project_name
      project.name
    end

    def project_recipients
      recipients = project.email_recipients.split(' ')

      if project.email_add_pusher? && user.present? && user.notification_email.present?
        recipients << user.notification_email
      end

      recipients.uniq
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
      rescue
        # if bad regex or something goes wrong we dont want to interrupt transition
        # so we just silentrly ignore error for now
      end
    end

    def raw_trace
      if File.exist?(path_to_trace)
        File.read(path_to_trace)
      else
        # backward compatibility
        read_attribute :trace
      end
    end

    def trace
      trace = raw_trace
      if project && trace.present?
        trace.gsub(project.token, 'xxxxxx')
      else
        trace
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

    def token
      project.token
    end

    def valid_token? token
      project.valid_token? token
    end

    def target_url
      Gitlab::Application.routes.url_helpers.
        namespace_project_build_url(gl_project.namespace, gl_project, self)
    end

    def cancel_url
      if active?
        Gitlab::Application.routes.url_helpers.
          cancel_namespace_project_build_path(gl_project.namespace, gl_project, self)
      end
    end

    def retry_url
      if retryable?
        Gitlab::Application.routes.url_helpers.
          retry_namespace_project_build_path(gl_project.namespace, gl_project, self)
      end
    end

    def can_be_served?(runner)
      (tag_list - runner.tag_list).empty?
    end

    def any_runners_online?
      project.any_runners? { |runner| runner.active? && runner.online? && can_be_served?(runner) }
    end

    def show_warning?
      pending? && !any_runners_online?
    end

    def download_url
      if artifacts_file.exists?
        Gitlab::Application.routes.url_helpers.
          download_namespace_project_build_path(gl_project.namespace, gl_project, self)
      end
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

    def predefined_variables
      variables = []
      variables << { key: :CI_BUILD_TAG, value: ref, public: true } if tag?
      variables << { key: :CI_BUILD_NAME, value: name, public: true }
      variables << { key: :CI_BUILD_STAGE, value: stage, public: true }
      variables << { key: :CI_BUILD_TRIGGERED, value: 'true', public: true } if trigger_request
      variables
    end
  end
end
