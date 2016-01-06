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

    before_destroy { project }

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
        new_build.gl_project_id = build.gl_project_id
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
      after_transition pending: :running do |build, transition|
        build.execute_hooks
      end

      after_transition any => [:success, :failed, :canceled] do |build, transition|
        return unless build.project

        build.update_coverage
        build.commit.create_next_builds(build)
        build.execute_hooks
      end
    end

    def ignored?
      failed? && allow_failure?
    end

    def retryable?
      project.builds_enabled? && commands.present?
    end

    def retried?
      !self.commit.latest_builds_for_ref(self.ref).include?(self)
    end

    def trace_html
      html = Ci::Ansi2html::convert(trace) if trace.present?
      html || ''
    end

    def timeout
      project.build_timeout
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

    def repo_url
      auth = "gitlab-ci-token:#{token}@"
      project.http_url_to_repo.sub(/^https?:\/\//) do |prefix|
        prefix + auth
      end
    end

    def allow_git_fetch
      project.build_allow_git_fetch
    end

    def update_coverage
      coverage_regex = project.build_coverage_regex
      return unless coverage_regex
      coverage = extract_coverage(trace, coverage_regex)

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
      if File.file?(path_to_trace)
        File.read(path_to_trace)
      elsif project.ci_id && File.file?(old_path_to_trace)
        # Temporary fix for build trace data integrity
        File.read(old_path_to_trace)
      else
        # backward compatibility
        read_attribute :trace
      end
    end

    def trace
      trace = raw_trace
      if project && trace.present? && project.runners_token.present?
        trace.gsub(project.runners_token, 'xxxxxx')
      else
        trace
      end
    end

    def trace=(trace)
      unless Dir.exists?(dir_to_trace)
        FileUtils.mkdir_p(dir_to_trace)
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

    ##
    # Deprecated
    #
    # This is a hotfix for CI build data integrity, see #4246
    # Should be removed in 8.4, after CI files migration has been done.
    #
    def old_dir_to_trace
      File.join(
        Settings.gitlab_ci.builds_path,
        created_at.utc.strftime("%Y_%m"),
        project.ci_id.to_s
      )
    end

    ##
    # Deprecated
    #
    # This is a hotfix for CI build data integrity, see #4246
    # Should be removed in 8.4, after CI files migration has been done.
    #
    def old_path_to_trace
      "#{old_dir_to_trace}/#{id}.log"
    end

    ##
    # Deprecated
    #
    # This contains a hotfix for CI build data integrity, see #4246
    #
    # This method is used by `ArtifactUploader` to create a store_dir.
    # Warning: Uploader uses it after AND before file has been stored.
    #
    # This method returns old path to artifacts only if it already exists.
    #
    def artifacts_path
      old = File.join(created_at.utc.strftime('%Y_%m'),
                      project.ci_id.to_s,
                      id.to_s)

      old_store = File.join(ArtifactUploader.artifacts_path, old)
      return old if project.ci_id && File.directory?(old_store)

      File.join(
        created_at.utc.strftime('%Y_%m'),
        project.id.to_s,
        id.to_s
      )
    end

    def token
      project.runners_token
    end

    def valid_token? token
      project.valid_runners_token? token
    end

    def target_url
      Gitlab::Application.routes.url_helpers.
        namespace_project_build_url(project.namespace, project, self)
    end

    def cancel_url
      if active?
        Gitlab::Application.routes.url_helpers.
          cancel_namespace_project_build_path(project.namespace, project, self)
      end
    end

    def retry_url
      if retryable?
        Gitlab::Application.routes.url_helpers.
          retry_namespace_project_build_path(project.namespace, project, self)
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
          download_namespace_project_build_path(project.namespace, project, self)
      end
    end

    def execute_hooks
      build_data = Gitlab::BuildDataBuilder.build(self)
      project.execute_hooks(build_data.dup, :build_hooks)
      project.execute_services(build_data.dup, :build_hooks)
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
