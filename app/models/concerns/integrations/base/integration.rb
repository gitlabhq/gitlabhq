# frozen_string_literal: true

module Integrations
  module Base
    module Integration
      extend ActiveSupport::Concern
      extend Gitlab::Utils::Override

      UnknownType = Class.new(StandardError)

      INTEGRATION_NAMES = %w[
        asana assembla bamboo bugzilla buildkite campfire clickup confluence custom_issue_tracker
        datadog diffblue_cover discord drone_ci emails_on_push ewm external_wiki
        gitlab_slack_application hangouts_chat harbor irker jira matrix
        mattermost mattermost_slash_commands microsoft_teams packagist phorge pipelines_email
        pivotaltracker prometheus pumble pushover redmine slack slack_slash_commands squash_tm teamcity telegram
        unify_circuit webex_teams youtrack zentao
      ].freeze

      # Integrations that can only be enabled on the instance-level
      INSTANCE_LEVEL_ONLY_INTEGRATION_NAMES = %w[
        beyond_identity
      ].freeze

      # Integrations that can only be enabled on the project-level
      PROJECT_LEVEL_ONLY_INTEGRATION_NAMES = %w[
        apple_app_store google_play jenkins
      ].freeze

      # Integrations that cannot be enabled on the instance-level
      PROJECT_AND_GROUP_LEVEL_ONLY_INTEGRATION_NAMES = %w[
        jira_cloud_app
      ].freeze

      # Fake integrations to help with local development.
      DEV_INTEGRATION_NAMES = %w[
        mock_ci mock_monitoring
      ].freeze

      # Base classes which aren't actual integrations.
      BASE_CLASSES = %w[].freeze

      BASE_ATTRIBUTES = %w[id instance project_id group_id created_at updated_at
        encrypted_properties encrypted_properties_iv properties].freeze

      SECTION_TYPE_CONFIGURATION = 'configuration'
      SECTION_TYPE_CONNECTION = 'connection'
      SECTION_TYPE_TRIGGER = 'trigger'

      SNOWPLOW_EVENT_ACTION = 'perform_integrations_action'
      SNOWPLOW_EVENT_LABEL = 'redis_hll_counters.ecosystem.ecosystem_total_unique_counts_monthly'

      class_methods do
        extend Gitlab::Utils::Override

        def supported_events
          %w[commit push tag_push issue confidential_issue merge_request wiki_page]
        end

        # rubocop:disable Gitlab/NoCodeCoverageComment -- existing code moved as is
        # :nocov: Tested on subclasses.
        def field(name, storage: field_storage, **attrs)
          fields << ::Integrations::Field.new(name: name, integration_class: self, **attrs)

          case storage
          when :attribute
            # noop
          when :properties
            prop_accessor(name)
          when :data_fields
            data_field(name)
          else
            raise ArgumentError, "Unknown field storage: #{storage}"
          end

          boolean_accessor(name) if attrs[:type] == :checkbox && storage != :attribute
        end
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment

        def fields
          @fields ||= []
        end

        # Provide convenient accessor methods for each serialized property.
        # Also keep track of updated properties in a similar way as ActiveModel::Dirty
        def prop_accessor(*args)
          args.each do |arg|
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              unless method_defined?(arg)
                def #{arg}
                  properties['#{arg}'] if properties.present?
                end
              end

              def #{arg}=(value)
                self.properties ||= {}
                updated_properties['#{arg}'] = #{arg} unless #{arg}_changed?
                self.properties = self.properties.merge('#{arg}' => value)
              end

              def #{arg}_changed?
                #{arg}_touched? && #{arg} != #{arg}_was
              end

              def #{arg}_touched?
                updated_properties.include?('#{arg}')
              end

              def #{arg}_was
                updated_properties['#{arg}']
              end
            RUBY
          end
        end

        # Provide convenient boolean accessor methods for each serialized property.
        # Also keep track of updated properties in a similar way as ActiveModel::Dirty
        def boolean_accessor(*args)
          args.each do |arg|
            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              # Make the original getter available as a private method.
              alias_method :#{arg}_before_type_cast, :#{arg}
              private(:#{arg}_before_type_cast)

              def #{arg}
                Gitlab::Utils.to_boolean(#{arg}_before_type_cast)
              end

              def #{arg}?
                # '!!' is used because nil or empty string is converted to nil
                !!#{arg}
              end
            RUBY
          end
        end

        def title
          raise NotImplementedError
        end

        def description
          raise NotImplementedError
        end

        def help
          # no-op
        end

        def to_param
          raise NotImplementedError
        end

        def attribution_notice
          # no-op
        end

        def event_names
          supported_events.map { |event| IntegrationsHelper.integration_event_field_name(event) }
        end

        def default_test_event
          'push'
        end

        def event_description(event)
          IntegrationsHelper.integration_event_description(event)
        end

        def find_or_initialize_non_project_specific_integration(name, instance: false, group_id: nil)
          return unless name.in?(available_integration_names(
            include_project_specific: false,
            include_group_specific: group_id.present?,
            include_instance_specific: instance))

          integration_name_to_model(name).find_or_initialize_by(instance: instance, group_id: group_id)
        end

        def find_or_initialize_all_non_project_specific(scope, include_instance_specific: false)
          scope + build_nonexistent_integrations_for(scope,
            include_group_specific: !include_instance_specific,
            include_instance_specific: include_instance_specific)
        end

        def build_nonexistent_integrations_for(...)
          nonexistent_integration_types_for(...).map do |type|
            integration_type_to_model(type).new
          end
        end

        # Returns a list of integration types that do not exist in the given scope.
        # Example: ["AsanaService", ...]
        def nonexistent_integration_types_for(
          scope,
          include_group_specific: false,
          include_instance_specific: false)
          # Using #map instead of #pluck to save one query count. This is because
          # ActiveRecord loaded the object here, so we don't need to query again later.
          available_integration_types(
            include_project_specific: false,
            include_group_specific: include_group_specific,
            include_instance_specific: include_instance_specific
          ) - scope.map(&:type)
        end

        # Returns a list of available integration names.
        # Example: ["asana", ...]
        def available_integration_names(
          include_project_specific: true,
          include_group_specific: true,
          include_instance_specific: true,
          include_dev: true,
          include_disabled: false)
          names = integration_names.dup
          names.concat(project_specific_integration_names) if include_project_specific
          names.concat(dev_integration_names) if include_dev
          names.concat(instance_specific_integration_names) if include_instance_specific

          if include_project_specific || include_group_specific
            names.concat(project_and_group_specific_integration_names)
          end

          names -= disabled_integration_names unless include_disabled

          names.sort_by(&:downcase)
        end

        def integration_names
          names = INTEGRATION_NAMES.dup

          unless Gitlab::CurrentSettings.slack_app_enabled || Gitlab.dev_or_test_env?
            names.delete('gitlab_slack_application')
          end

          names
        end

        def instance_specific_integration_names
          INSTANCE_LEVEL_ONLY_INTEGRATION_NAMES
        end

        def instance_specific_integration_types
          instance_specific_integration_names.map { |name| integration_name_to_type(name) }
        end

        def dev_integration_names
          return [] unless Gitlab.dev_or_test_env?

          DEV_INTEGRATION_NAMES
        end

        def project_specific_integration_names
          PROJECT_LEVEL_ONLY_INTEGRATION_NAMES.dup
        end

        def project_and_group_specific_integration_names
          PROJECT_AND_GROUP_LEVEL_ONLY_INTEGRATION_NAMES.dup
        end

        # Returns a list of available integration types.
        # Example: ["Integrations::Asana", ...]
        def available_integration_types(...)
          available_integration_names(...).map do # rubocop:disable Style/NumberedParameters -- existing code moved as is
            integration_name_to_type(_1)
          end
        end

        # Returns a list of disabled integration names.
        # Example: ["gitlab_slack_application", ...]
        def disabled_integration_names
          # The GitLab for Slack app integration is only available when enabled through settings.
          # The Slack Slash Commands integration is only available for customers
          # who cannot use the GitLab for Slack app.
          disabled = Gitlab::CurrentSettings.slack_app_enabled ? ['slack_slash_commands'] : ['gitlab_slack_application']
          disabled += ['jira_cloud_app'] unless Gitlab::CurrentSettings.jira_connect_application_key.present?
          disabled
        end

        # Returns the model for the given integration name.
        # Example: :asana => Integrations::Asana
        def integration_name_to_model(name)
          type = integration_name_to_type(name)
          integration_type_to_model(type)
        end

        # Returns the STI type for the given integration name.
        # Example: "asana" => "Integrations::Asana"
        def integration_name_to_type(name)
          name = name.to_s
          if all_integration_names.include?(name)
            "Integrations::#{name.camelize}"
          else
            Gitlab::ErrorTracking.track_and_raise_for_dev_exception(UnknownType.new(name.inspect))
          end
        end

        # Returns the model for the given STI type.
        # Example: "Integrations::Asana" => Integrations::Asana
        def integration_type_to_model(type)
          type.constantize
        end

        def build_from_integration(integration, project_id: nil, group_id: nil)
          new_integration = integration.dup

          new_integration.instance = false
          new_integration.project_id = project_id
          new_integration.group_id = group_id
          new_integration.inherit_from_id = integration.id if integration.inheritable?
          new_integration
        end

        def instance_exists_for?(type)
          exists?(instance: true, type: type)
        end

        # Returns the names of all integrations, including:
        #
        # - All project, group and instance-level only integrations
        # - Integrations that are not available on the instance
        # - Development-only integrations
        def all_integration_names
          available_integration_names(include_disabled: true)
        end

        def default_integration(type, scope)
          closest_group_integration(type, scope) || instance_level_integration(type)
        end

        def closest_group_integration(type, scope)
          group_ids = scope.ancestors(hierarchy_order: :asc).reselect(:id)
          array = group_ids.to_sql.present? ? "array(#{group_ids.to_sql})" : 'ARRAY[]'

          where(type: type, group_id: group_ids, inherit_from_id: nil)
            .order(Arel.sql("array_position(#{array}::bigint[], #{table_name}.group_id)"))
            .first
        end

        def instance_level_integration(type)
          find_by(type: type, instance: true)
        end

        def default_integrations(owner, scope)
          group_ids = sorted_ancestors(owner).select(:id)
          array = group_ids.to_sql.present? ? "array(#{group_ids.to_sql})" : 'ARRAY[]'
          order = Arel.sql("type_new ASC, array_position(#{array}::bigint[], #{table_name}.group_id), instance DESC")
          from_union([scope.where(instance: true), scope.where(group_id: group_ids, inherit_from_id: nil)])
            .order(order)
            .group_by(&:type)
            .transform_values(&:first)
        end

        def create_from_default_integrations(owner, association)
          active_default_count = create_from_active_default_integrations(owner, association)
          default_instance_specific_count = create_from_default_instance_specific_integrations(owner, association)
          active_default_count + default_instance_specific_count
        end

        # Returns the number of successfully saved integrations
        # Duplicate integrations are excluded from this count by their validations.
        def create_from_active_default_integrations(owner, association)
          default_integrations(
            owner,
            active.where.not(type: instance_specific_integration_types)
          ).count { |_type, integration| build_from_integration(integration, association => owner.id).save }
        end

        def create_from_default_instance_specific_integrations(owner, association)
          default_integrations(
            owner,
            where(type: instance_specific_integration_types)
          ).count { |_type, integration| build_from_integration(integration, association => owner.id).save }
        end

        def descendants_from_self_or_ancestors_from(integration)
          scope = where(type: integration.type)
          from_union([
            scope.where(group: integration.group.descendants),
            scope.where(project: Project.in_namespace(integration.group.self_and_descendants))
          ])
        end

        def inherited_descendants_from_self_or_ancestors_from(integration)
          inherit_from_ids =
            where(type: integration.type, group: integration.group.self_and_ancestors)
              .or(where(type: integration.type, instance: true)).select(:id)

          from_union([
            where(type: integration.type, inherit_from_id: inherit_from_ids, group: integration.group.descendants),
            where(
              type: integration.type,
              inherit_from_id: inherit_from_ids,
              project: Project.in_namespace(integration.group.self_and_descendants)
            )
          ])
        end

        def api_arguments
          fields.filter_map do |field|
            next if field.if != true

            {
              required: field.required?,
              name: field.name.to_sym,
              type: field.api_type,
              desc: field.description
            }
          end
        end

        def instance_specific?
          false
        end

        def pluck_group_id
          pluck(:group_id) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- existing code moved as is
        end

        private

        attr_writer :field_storage

        def field_storage
          @field_storage || :properties
        end

        def build_help_page_url(url_path, help_text, link_text = _("Learn More"), options = {})
          docs_link = ActionController::Base.helpers.link_to(
            '',
            Rails.application.routes.url_helpers.help_page_url(url_path, **options), # rubocop:disable Gitlab/DocumentationLinks/Link: -- existing code moved as is
            target: '_blank',
            rel: 'noopener noreferrer'
          )
          tag_pair_docs_link = tag_pair(docs_link, :link_start, :link_end)

          safe_format(help_text + " %{link_start}#{link_text}%{link_end}.", tag_pair_docs_link)
        end

        # Ancestors sorted by hierarchy depth in bottom-top order.
        def sorted_ancestors(scope)
          if scope.root_ancestor.use_traversal_ids?
            Namespace.from(scope.ancestors(hierarchy_order: :asc))
          else
            scope.ancestors
          end
        end
      end

      included do
        include Sortable
        include Importable
        include Integrations::Loggable
        include Integrations::HasDataFields
        include Integrations::ResetSecretFields
        include FromUnion
        include EachBatch
        extend SafeFormatHelper
        extend ::Gitlab::Utils::Override

        self.allow_legacy_sti_class = true
        self.inheritance_column = :type_new # rubocop:disable Database/AvoidInheritanceColumn -- existing code moved as is

        attr_encrypted :properties,
          mode: :per_attribute_iv,
          key: Settings.attr_encrypted_db_key_base_32,
          algorithm: 'aes-256-gcm',
          marshal: true,
          marshaler: ::Gitlab::Json,
          encode: false,
          encode_iv: false

        alias_attribute :name, :title
        # Handle assignment of props with symbol keys.
        # To do this correctly, we need to call the method generated by attr_encrypted.
        alias_method :attr_encrypted_props=, :properties=
        private :attr_encrypted_props=

        def properties=(props)
          self.attr_encrypted_props = props&.with_indifferent_access&.freeze
        end

        alias_attribute :type, :type_new

        attribute :active, default: false
        attribute :alert_events, default: true
        attribute :incident_events, default: false
        attribute :category, default: 'common'
        attribute :commit_events, default: true
        attribute :confidential_issues_events, default: true
        attribute :confidential_note_events, default: true
        attribute :deployment_events, default: false
        attribute :issues_events, default: true
        attribute :job_events, default: true
        attribute :merge_requests_events, default: true
        attribute :note_events, default: true
        attribute :pipeline_events, default: true
        attribute :push_events, default: true
        attribute :tag_push_events, default: true
        attribute :wiki_page_events, default: true
        attribute :group_mention_events, default: false
        attribute :group_confidential_mention_events, default: false

        after_initialize :initialize_properties

        after_commit :reset_updated_properties

        belongs_to :project, inverse_of: :integrations
        belongs_to :group, inverse_of: :integrations

        validates :project_id, presence: true, unless: -> { instance_level? || group_level? }
        validates :group_id, presence: true, unless: -> { instance_level? || project_level? }
        validates :project_id, :group_id, absence: true, if: -> { instance_level? }
        validates :type, presence: true, exclusion: BASE_CLASSES
        validates :type, uniqueness: { scope: :instance }, if: :instance_level?
        validates :type, uniqueness: { scope: :project_id }, if: :project_level?
        validates :type, uniqueness: { scope: :group_id }, if: :group_level?
        validate :validate_belongs_to_project_or_group

        scope :external_issue_trackers, -> { where(category: 'issue_tracker').active }
        scope :third_party_wikis, -> { where(category: 'third_party_wiki').active }
        scope :by_name, ->(name) { by_type(integration_name_to_type(name)) }
        scope :external_wikis, -> { by_name(:external_wiki).active }
        scope :active, -> { where(active: true) }
        scope :by_type, ->(type) { where(type: type) } # INTERNAL USE ONLY: use by_name instead
        scope :by_active_flag, ->(flag) { where(active: flag) }
        scope :inherit_from_id, ->(id) { where(inherit_from_id: id) }
        scope :with_default_settings, -> { where.not(inherit_from_id: nil) }
        scope :with_custom_settings, -> { where(inherit_from_id: nil) }
        scope :for_group, ->(group) {
          types = available_integration_types(include_project_specific: false)
          where(group_id: group, type: types)
        }

        scope :for_instance, -> {
          types = available_integration_types(include_project_specific: false, include_group_specific: false)
          where(instance: true, type: types)
        }

        scope :push_hooks, -> { where(push_events: true).active }
        scope :tag_push_hooks, -> { where(tag_push_events: true).active }
        scope :issue_hooks, -> { where(issues_events: true).active }
        scope :confidential_issue_hooks, -> { where(confidential_issues_events: true).active }
        scope :merge_request_hooks, -> { where(merge_requests_events: true).active }
        scope :note_hooks, -> { where(note_events: true).active }
        scope :confidential_note_hooks, -> { where(confidential_note_events: true).active }
        scope :job_hooks, -> { where(job_events: true).active }
        scope :archive_trace_hooks, -> { where(archive_trace_events: true).active }
        scope :pipeline_hooks, -> { where(pipeline_events: true).active }
        scope :wiki_page_hooks, -> { where(wiki_page_events: true).active }
        scope :deployment_hooks, -> { where(deployment_events: true).active }
        scope :alert_hooks, -> { where(alert_events: true).active }
        scope :incident_hooks, -> { where(incident_events: true).active }
        scope :deployment, -> { where(category: 'deployment') }
        scope :group_mention_hooks, -> { where(group_mention_events: true).active }
        scope :group_confidential_mention_hooks, -> { where(group_confidential_mention_events: true).active }
        scope :exclusions_for_project, ->(project) { where(project: project, active: false) }

        private_class_method :boolean_accessor
        private_class_method :build_nonexistent_integrations_for
        private_class_method :nonexistent_integration_types_for
        private_class_method :project_and_group_specific_integration_names
        private_class_method :disabled_integration_names
        private_class_method :integration_type_to_model
        private_class_method :default_integrations
        private_class_method :instance_level_integration
        private_class_method :closest_group_integration
      end

      def fields
        self.class.fields.dup
      end

      # Duplicating an integration also duplicates the data fields. Duped records have different ciphertexts.
      override :dup
      def dup
        new_integration = super
        new_integration.assign_attributes(reencrypt_properties)

        if supports_data_fields?
          fields = data_fields.dup
          fields.integration = new_integration
        end

        new_integration
      end

      def inheritable?
        instance_level? || group_level?
      end

      def activated?
        active
      end

      def operating?
        active && persisted?
      end

      def manual_activation?
        true
      end

      def editable?
        true
      end

      def activate_disabled_reason
        nil
      end

      def category
        read_attribute(:category).to_sym
      end

      def initialize_properties
        self.properties = {} if has_attribute?(:encrypted_properties) && encrypted_properties.nil?
      end

      def title
        self.class.title
      end

      def description
        self.class.description
      end

      def help
        self.class.help
      end

      def to_param
        self.class.to_param
      end

      def attribution_notice
        self.class.attribution_notice
      end

      def sections
        []
      end

      def secret_fields
        fields.select(&:secret?).pluck(:name) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- existing code moved as is
      end

      # Expose a list of fields in the JSON endpoint.
      #
      # This list is used in `Integration#as_json(only: json_fields)`.
      def json_fields
        %w[active]
      end

      # properties is always nil - ignore it.
      override :attributes
      def attributes
        super.except('properties')
      end

      # Returns a hash of attributes (columns => values) used for inserting into the database.
      def to_database_hash
        column = self.class.attribute_aliases.fetch('type', 'type')

        attributes_for_database
          .except(*BASE_ATTRIBUTES)
          .merge(column => type)
          .merge(reencrypt_properties)
      end

      def reencrypt_properties
        unless properties.nil? || properties.empty?
          alg = self.class.attr_encrypted_attributes[:properties][:algorithm]
          iv = generate_iv(alg)
          ep = self.class.attr_encrypt(:properties, properties, { iv: iv })
        end

        { 'encrypted_properties' => ep, 'encrypted_properties_iv' => iv }
      end

      def event_channel_names
        []
      end

      def event_names
        self.class.event_names
      end

      def api_field_names
        fields # rubocop:disable Style/NumberedParameters -- existing code moved as is
          .reject { _1[:type] == :password || _1[:name] == 'webhook' || (_1.key?(:if) && _1[:if] != true) }
          .pluck(:name) # rubocop:disable Database/AvoidUsingPluckWithoutLimit -- existing code moved as is
      end

      def form_fields
        fields.reject { _1[:api_only] == true || (_1.key?(:if) && _1[:if] != true) } # rubocop:disable Style/NumberedParameters -- existing code moved as is
      end

      def configurable_events
        events = supported_events

        # No need to disable individual triggers when there is only one
        if events.count == 1
          []
        else
          events
        end
      end

      def supported_events
        self.class.supported_events
      end

      def default_test_event
        self.class.default_test_event
      end

      def execute(data)
        # implement inside child
      end

      def test(data)
        # default implementation
        result = execute(data)
        { success: result.present?, result: result }
      end

      # Disable test for instance-level and group-level integrations.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/213138
      def testable?
        project_level?
      end

      def project_level?
        project_id.present?
      end

      def group_level?
        group_id.present?
      end

      def instance_level?
        instance?
      end

      def parent
        project || group
      end

      # Returns a hash of the properties that have been assigned a new value since last save,
      # indicating their original values (attr => original value).
      # ActiveRecord does not provide a mechanism to track changes in serialized keys,
      # so we need a specific implementation for integration properties.
      # This allows to track changes to properties set with the accessor methods,
      # but not direct manipulation of properties hash.
      def updated_properties
        @updated_properties ||= ActiveSupport::HashWithIndifferentAccess.new
      end

      def reset_updated_properties
        @updated_properties = nil # rubocop:disable Gitlab/ModuleWithInstanceVariables -- legacy use
      end

      def async_execute(data)
        return if ::Gitlab::SilentMode.enabled?
        return unless active?

        # Temporarily log when we return within this method to gather data for
        # https://gitlab.com/gitlab-org/gitlab/-/issues/382999
        unless supported_events.include?(data[:object_kind])
          log_info(
            'async_execute did nothing due to event not being supported',
            event: data[:object_kind]
          )
          return
        end

        Integrations::ExecuteWorker.perform_async(id, data.deep_stringify_keys)
      end

      # override if needed
      def supports_data_fields?
        false
      end

      def chat?
        category == :chat
      end

      def ci?
        category == :ci
      end

      def deactivate!
        update(active: false)
      end

      def activate!
        update(active: true)
      end

      def toggle!
        active? ? deactivate! : activate!
      end

      private

      def validate_belongs_to_project_or_group
        return unless project_level? && group_level?

        errors.add(:project_id, 'The integration cannot belong to both a project and a group')
      end

      def validate_recipients?
        activated? && !importing?
      end
    end
  end
end

Integration.prepend_mod_with('Integrations::Base::Integration')
