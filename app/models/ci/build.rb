module Ci
  class Build < CommitStatus
    belongs_to :runner, class_name: 'Ci::Runner'
    belongs_to :trigger_request, class_name: 'Ci::TriggerRequest'
    belongs_to :erased_by, class_name: 'User'

    serialize :options
    serialize :yaml_variables

    validates :coverage, numericality: true, allow_blank: true
    validates_presence_of :ref

    scope :unstarted, ->() { where(runner_id: nil) }
    scope :ignore_failures, ->() { where(allow_failure: false) }
    scope :with_artifacts, ->() { where.not(artifacts_file: nil) }
    scope :with_expired_artifacts, ->() { with_artifacts.where('artifacts_expire_at < ?', Time.now) }
    scope :last_month, ->() { where('created_at > ?', Date.today - 1.month) }
    scope :manual_actions, ->() { where(when: :manual) }

    mount_uploader :artifacts_file, ArtifactUploader
    mount_uploader :artifacts_metadata, ArtifactUploader

    acts_as_taggable

    before_save :update_artifacts_size, if: :artifacts_file_changed?
    before_destroy { project }

    after_create :execute_hooks

    class << self
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

      def retry(build, user = nil)
        new_build = Ci::Build.new(status: 'pending')
        new_build.ref = build.ref
        new_build.tag = build.tag
        new_build.options = build.options
        new_build.commands = build.commands
        new_build.tag_list = build.tag_list
        new_build.project = build.project
        new_build.pipeline = build.pipeline
        new_build.name = build.name
        new_build.allow_failure = build.allow_failure
        new_build.stage = build.stage
        new_build.stage_idx = build.stage_idx
        new_build.trigger_request = build.trigger_request
        new_build.yaml_variables = build.yaml_variables
        new_build.when = build.when
        new_build.user = user
        new_build.environment = build.environment
        new_build.save
        MergeRequests::AddTodoWhenBuildFailsService.new(build.project, nil).close(new_build)
        new_build
      end
    end

    state_machine :status, initial: :pending do
      after_transition pending: :running do |build|
        build.execute_hooks
      end

      # We use around_transition to create builds for next stage as soon as possible, before the `after_*` is executed
      around_transition any => [:success, :failed, :canceled] do |build, block|
        block.call
        build.pipeline.create_next_builds(build) if build.pipeline
      end

      after_transition any => [:success, :failed, :canceled] do |build|
        build.update_coverage
        build.execute_hooks
      end

      after_transition any => [:success] do |build|
        if build.environment.present?
          service = CreateDeploymentService.new(build.project, build.user,
                                                environment: build.environment,
                                                sha: build.sha,
                                                ref: build.ref,
                                                tag: build.tag)
          service.execute(build)
        end
      end
    end

    def manual?
      self.when == 'manual'
    end

    def other_actions
      pipeline.manual_actions.where.not(id: self)
    end

    def playable?
      project.builds_enabled? && commands.present? && manual?
    end

    def play(current_user = nil)
      # Try to queue a current build
      if self.queue
        self.update(user: current_user)
        self
      else
        # Otherwise we need to create a duplicate
        Ci::Build.retry(self, current_user)
      end
    end

    def retryable?
      project.builds_enabled? && commands.present? && complete?
    end

    def retried?
      !self.pipeline.statuses.latest.include?(self)
    end

    def depends_on_builds
      # Get builds of the same type
      latest_builds = self.pipeline.builds.latest

      # Return builds from previous stages
      latest_builds.where('stage_idx < ?', stage_idx)
    end

    def trace_html
      trace_with_state[:html] || ''
    end

    def trace_with_state(state = nil)
      trace_with_state = Ci::Ansi2html::convert(trace, state) if trace.present?
      trace_with_state || {}
    end

    def timeout
      project.build_timeout
    end

    def variables
      predefined_variables + yaml_variables + project_variables + trigger_variables
    end

    def merge_request
      merge_requests = MergeRequest.includes(:merge_request_diff)
                                   .where(source_branch: ref, source_project_id: pipeline.gl_project_id)
                                   .reorder(iid: :asc)

      merge_requests.find do |merge_request|
        merge_request.commits.any? { |ci| ci.id == pipeline.sha }
      end
    end

    def project_id
      gl_project_id
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
      return unless project
      coverage_regex = project.build_coverage_regex
      return unless coverage_regex
      coverage = extract_coverage(trace, coverage_regex)

      if coverage.is_a? Numeric
        update_attributes(coverage: coverage)
      end
    end

    def extract_coverage(text, regex)
      begin
        matches = text.scan(Regexp.new(regex)).last
        matches = matches.last if matches.kind_of?(Array)
        coverage = matches.gsub(/\d+(\.\d+)?/).first

        if coverage.present?
          coverage.to_f
        end
      rescue
        # if bad regex or something goes wrong we dont want to interrupt transition
        # so we just silentrly ignore error for now
      end
    end

    def has_trace?
      raw_trace.present?
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

    def trace_length
      if raw_trace
        raw_trace.bytesize
      else
        0
      end
    end

    def trace=(trace)
      recreate_trace_dir
      File.write(path_to_trace, trace)
    end

    def recreate_trace_dir
      unless Dir.exist?(dir_to_trace)
        FileUtils.mkdir_p(dir_to_trace)
      end
    end
    private :recreate_trace_dir

    def append_trace(trace_part, offset)
      recreate_trace_dir

      File.truncate(path_to_trace, offset) if File.exist?(path_to_trace)
      File.open(path_to_trace, 'ab') do |f|
        f.write(trace_part)
      end
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

    def valid_token?(token)
      project.valid_runners_token? token
    end

    def has_tags?
      tag_list.any?
    end

    def any_runners_online?
      project.any_runners? { |runner| runner.active? && runner.online? && runner.can_pick?(self) }
    end

    def stuck?
      pending? && !any_runners_online?
    end

    def execute_hooks
      return unless project
      build_data = Gitlab::BuildDataBuilder.build(self)
      project.execute_hooks(build_data.dup, :build_hooks)
      project.execute_services(build_data.dup, :build_hooks)
      PagesService.new(build_data).execute
      project.running_or_pending_build_count(force: true)
    end

    def artifacts?
      !artifacts_expired? && artifacts_file.exists?
    end

    def artifacts_metadata?
      artifacts? && artifacts_metadata.exists?
    end

    def artifacts_metadata_entry(path, **options)
      metadata = Gitlab::Ci::Build::Artifacts::Metadata.new(
        artifacts_metadata.path,
        path,
        **options)

      metadata.to_entry
    end

    def erase_artifacts!
      remove_artifacts_file!
      remove_artifacts_metadata!
      save
    end

    def erase(opts = {})
      return false unless erasable?

      erase_artifacts!
      erase_trace!
      update_erased!(opts[:erased_by])
    end

    def erasable?
      complete? && (artifacts? || has_trace?)
    end

    def erased?
      !self.erased_at.nil?
    end

    def artifacts_expired?
      artifacts_expire_at && artifacts_expire_at < Time.now
    end

    def artifacts_expire_in
      artifacts_expire_at - Time.now if artifacts_expire_at
    end

    def artifacts_expire_in=(value)
      self.artifacts_expire_at =
        if value
          Time.now + ChronicDuration.parse(value)
        end
    end

    def keep_artifacts!
      self.update(artifacts_expire_at: nil)
    end

    def when
      read_attribute(:when) || build_attributes_from_config[:when] || 'on_success'
    end

    def yaml_variables
      read_attribute(:yaml_variables) || build_attributes_from_config[:yaml_variables] || []
    end

    private

    def update_artifacts_size
      self.artifacts_size = if artifacts_file.exists?
                              artifacts_file.size
                            else
                              nil
                            end
    end

    def erase_trace!
      self.trace = nil
    end

    def update_erased!(user = nil)
      self.update(erased_by: user, erased_at: Time.now, artifacts_expire_at: nil)
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

    def build_attributes_from_config
      return {} unless pipeline.config_processor
      
      pipeline.config_processor.build_attributes(name)
    end
  end
end
