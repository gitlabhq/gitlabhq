# frozen_string_literal: true

module Gitlab
  # A GitLab-rails specific accessor for `Labkit::Logging::ApplicationContext`
  class ApplicationContext
    include Gitlab::Utils::LazyAttributes
    include Gitlab::Utils::StrongMemoize

    Attribute = Struct.new(:name, :type)

    LOG_KEY = Labkit::Context::LOG_KEY
    KNOWN_KEYS = [
      :organization_id,
      :user,
      :user_id,
      :scoped_user,
      :scoped_user_id,
      :project,
      :root_namespace,
      :client_id,
      :caller_id,
      :remote_ip,
      :job_id,
      :pipeline_id,
      :related_class,
      :feature_category,
      :artifact_size,
      :artifact_used_cdn,
      :artifacts_dependencies_size,
      :artifacts_dependencies_count,
      :root_caller_id,
      :merge_action_status,
      :bulk_import_entity_id,
      :sidekiq_destination_shard_redis,
      :auth_fail_reason,
      :auth_fail_token_id,
      :auth_fail_requested_scopes,
      :http_router_rule_action,
      :http_router_rule_type
    ].freeze
    private_constant :KNOWN_KEYS

    WEB_ONLY_KEYS = [
      :auth_fail_reason,
      :auth_fail_token_id,
      :auth_fail_requested_scopes,
      :http_router_rule_action,
      :http_router_rule_type
    ].freeze
    private_constant :WEB_ONLY_KEYS

    APPLICATION_ATTRIBUTES = [
      Attribute.new(:organization, ::Organizations::Organization),
      Attribute.new(:project, Project),
      Attribute.new(:namespace, Namespace),
      Attribute.new(:user, User),
      Attribute.new(:scoped_user, User),
      Attribute.new(:runner, ::Ci::Runner),
      Attribute.new(:caller_id, String),
      Attribute.new(:remote_ip, String),
      Attribute.new(:job, ::Ci::Build),
      Attribute.new(:related_class, String),
      Attribute.new(:feature_category, String),
      Attribute.new(:artifact, ::Ci::JobArtifact),
      Attribute.new(:artifact_used_cdn, Object),
      Attribute.new(:artifacts_dependencies_size, Integer),
      Attribute.new(:artifacts_dependencies_count, Integer),
      Attribute.new(:root_caller_id, String),
      Attribute.new(:merge_action_status, String),
      Attribute.new(:bulk_import_entity_id, Integer),
      Attribute.new(:sidekiq_destination_shard_redis, String),
      Attribute.new(:auth_fail_reason, String),
      Attribute.new(:auth_fail_token_id, String),
      Attribute.new(:auth_fail_requested_scopes, String),
      Attribute.new(:http_router_rule_action, String),
      Attribute.new(:http_router_rule_type, String)
    ].freeze
    private_constant :APPLICATION_ATTRIBUTES

    def self.known_keys
      KNOWN_KEYS
    end

    # Sidekiq jobs may be deleted by matching keys in ApplicationContext.
    # Filter out keys that aren't available in Sidekiq jobs.
    def self.allowed_job_keys
      known_keys - WEB_ONLY_KEYS
    end

    def self.application_attributes
      APPLICATION_ATTRIBUTES
    end

    def self.with_context(args, &block)
      application_context = new(**args)
      application_context.use(&block)
    end

    def self.with_raw_context(attributes = {}, &block)
      Labkit::Context.with_context(attributes, &block)
    end

    def self.push(args)
      application_context = new(**args)
      Labkit::Context.push(application_context.to_lazy_hash)
    end

    def self.current
      Labkit::Context.current.to_h
    end

    def self.current_context_include?(attribute_name)
      current.include?(Labkit::Context.log_key(attribute_name))
    end

    def self.current_context_attribute(attribute_name)
      Labkit::Context.current&.get_attribute(attribute_name)
    end

    def initialize(**args)
      unknown_attributes = args.keys - self.class.application_attributes.map(&:name)
      raise ArgumentError, "#{unknown_attributes} are not known keys" if unknown_attributes.any?

      @set_values = args.keys

      assign_attributes(args)
      set_attr_readers
    end

    # rubocop: disable Metrics/AbcSize
    # rubocop: disable Metrics/CyclomaticComplexity -- inherently leads to higher cyclomatic due to
    #   all the conditional assignments, the added complexity from adding more abstractions like
    #   `assign_hash_if_value` is not worth the tradeoff.
    # rubocop: disable Metrics/PerceivedComplexity -- same as above
    def to_lazy_hash
      {}.tap do |hash|
        assign_hash_if_value(hash, :caller_id)
        assign_hash_if_value(hash, :root_caller_id)
        assign_hash_if_value(hash, :remote_ip)
        assign_hash_if_value(hash, :related_class)
        assign_hash_if_value(hash, :feature_category)
        assign_hash_if_value(hash, :artifact_used_cdn)
        assign_hash_if_value(hash, :artifacts_dependencies_size)
        assign_hash_if_value(hash, :artifacts_dependencies_count)
        assign_hash_if_value(hash, :merge_action_status)
        assign_hash_if_value(hash, :bulk_import_entity_id)
        assign_hash_if_value(hash, :sidekiq_destination_shard_redis)
        assign_hash_if_value(hash, :auth_fail_reason)
        assign_hash_if_value(hash, :auth_fail_token_id)
        assign_hash_if_value(hash, :auth_fail_requested_scopes)
        assign_hash_if_value(hash, :http_router_rule_action)
        assign_hash_if_value(hash, :http_router_rule_type)
        assign_hash_if_value(hash, :bulk_import_entity_id)

        hash[:user] = -> { username } if include_user?
        hash[:user_id] = -> { user_id } if include_user?
        hash[:scoped_user] = -> { scoped_user&.username } if include_scoped_user?
        hash[:scoped_user_id] = -> { scoped_user&.id } if include_scoped_user?
        hash[:project] = -> { project_path } if include_project?
        hash[:organization_id] = -> { organization&.id } if set_values.include?(:organization)
        hash[:root_namespace] = -> { root_namespace_path } if include_namespace?
        hash[:client_id] = -> { client } if include_client?
        hash[:pipeline_id] = -> { job&.pipeline_id } if set_values.include?(:job)
        hash[:job_id] = -> { job&.id } if set_values.include?(:job)
        hash[:artifact_size] = -> { artifact&.size } if set_values.include?(:artifact)
      end
    end
    # rubocop: enable Metrics/CyclomaticComplexity
    # rubocop: enable Metrics/AbcSize
    # rubocop: enable Metrics/PerceivedComplexity

    def use
      Labkit::Context.with_context(to_lazy_hash) { yield }
    end

    private

    attr_reader :set_values

    def set_attr_readers
      self.class.application_attributes.each do |attr|
        self.class.lazy_attr_reader attr.name, type: attr.type
      end
    end

    def assign_hash_if_value(hash, attribute_name)
      unless self.class.known_keys.include?(attribute_name)
        raise ArgumentError, "unknown attribute `#{attribute_name}`"
      end

      # rubocop:disable GitlabSecurity/PublicSend
      hash[attribute_name] = public_send(attribute_name) if set_values.include?(attribute_name)
      # rubocop:enable GitlabSecurity/PublicSend
    end

    def assign_attributes(values)
      values.slice(*self.class.application_attributes.map(&:name)).each do |name, value|
        instance_variable_set("@#{name}", value)
      end
    end

    def project_path
      associated_routable = project || runner_project || job_project
      associated_routable&.full_path
    end

    def username
      associated_user = user || job_user
      associated_user&.username
    end

    def user_id
      associated_user = user || job_user
      associated_user&.id
    end

    def root_namespace_path
      associated_routable = namespace || project || runner_project || runner_group || job_project
      associated_routable&.full_path_components&.first
    end

    def include_namespace?
      set_values.include?(:namespace) || set_values.include?(:project) || set_values.include?(:runner) || set_values.include?(:job)
    end

    def include_client?
      # Don't overwrite an existing more specific client id with an `ip/` one.
      original_client_id = self.class.current_context_attribute(:client_id).to_s
      return false if original_client_id.starts_with?('user/') || original_client_id.starts_with?('runner/')

      include_user? || set_values.include?(:runner) || set_values.include?(:remote_ip)
    end

    def include_user?
      set_values.include?(:user) || set_values.include?(:job)
    end

    def include_scoped_user?
      set_values.include?(:scoped_user)
    end

    def include_project?
      set_values.include?(:project) || set_values.include?(:runner) || set_values.include?(:job)
    end

    def client
      if runner
        "runner/#{runner.id}"
      elsif user_id
        "user/#{user_id}"
      else
        "ip/#{remote_ip}"
      end
    end

    def runner_project
      strong_memoize(:runner_project) do
        next unless runner&.project_type?

        runner.owner
      end
    end

    def runner_group
      strong_memoize(:runner_group) do
        next unless runner&.group_type?

        runner.owner
      end
    end

    def job_project
      strong_memoize(:job_project) do
        job&.project
      end
    end

    def job_user
      strong_memoize(:job_user) do
        job&.user
      end
    end
  end
end

Gitlab::ApplicationContext.prepend_mod_with('Gitlab::ApplicationContext')
