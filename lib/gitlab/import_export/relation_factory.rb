# frozen_string_literal: true

module Gitlab
  module ImportExport
    class RelationFactory
      prepend_if_ee('::EE::Gitlab::ImportExport::RelationFactory') # rubocop: disable Cop/InjectEnterpriseEditionModule

      OVERRIDES = { snippets: :project_snippets,
                    ci_pipelines: 'Ci::Pipeline',
                    pipelines: 'Ci::Pipeline',
                    stages: 'Ci::Stage',
                    statuses: 'commit_status',
                    triggers: 'Ci::Trigger',
                    pipeline_schedules: 'Ci::PipelineSchedule',
                    builds: 'Ci::Build',
                    runners: 'Ci::Runner',
                    hooks: 'ProjectHook',
                    merge_access_levels: 'ProtectedBranch::MergeAccessLevel',
                    push_access_levels: 'ProtectedBranch::PushAccessLevel',
                    create_access_levels: 'ProtectedTag::CreateAccessLevel',
                    labels: :project_labels,
                    priorities: :label_priorities,
                    auto_devops: :project_auto_devops,
                    label: :project_label,
                    custom_attributes: 'ProjectCustomAttribute',
                    project_badges: 'Badge',
                    metrics: 'MergeRequest::Metrics',
                    ci_cd_settings: 'ProjectCiCdSetting',
                    error_tracking_setting: 'ErrorTracking::ProjectErrorTrackingSetting',
                    links: 'Releases::Link',
                    metrics_setting: 'ProjectMetricsSetting' }.freeze

      USER_REFERENCES = %w[author_id assignee_id updated_by_id merged_by_id latest_closed_by_id user_id created_by_id last_edited_by_id merge_user_id resolved_by_id closed_by_id owner_id].freeze

      PROJECT_REFERENCES = %w[project_id source_project_id target_project_id].freeze

      BUILD_MODELS = %i[Ci::Build commit_status].freeze

      IMPORTED_OBJECT_MAX_RETRIES = 5.freeze

      EXISTING_OBJECT_CHECK = %i[milestone milestones label labels project_label project_labels group_label group_labels project_feature merge_request ProjectCiCdSetting container_expiration_policy].freeze

      TOKEN_RESET_MODELS = %i[Project Namespace Ci::Trigger Ci::Build Ci::Runner ProjectHook].freeze

      # This represents all relations that have unique key on `project_id`
      UNIQUE_RELATIONS = %i[project_feature ProjectCiCdSetting container_expiration_policy].freeze

      def self.create(*args)
        new(*args).create
      end

      def self.relation_class(relation_name)
        # There are scenarios where the model is pluralized (e.g.
        # MergeRequest::Metrics), and we don't want to force it to singular
        # with #classify.
        relation_name.to_s.classify.constantize
      rescue NameError
        relation_name.to_s.constantize
      end

      def initialize(relation_sym:, relation_hash:, members_mapper:, merge_requests_mapping:, user:, project:, excluded_keys: [])
        @relation_name = self.class.overrides[relation_sym]&.to_sym || relation_sym
        @relation_hash = relation_hash.except('noteable_id')
        @members_mapper = members_mapper
        @merge_requests_mapping = merge_requests_mapping
        @user = user
        @project = project
        @imported_object_retries = 0

        @relation_hash['project_id'] = @project.id

        # Remove excluded keys from relation_hash
        # We don't do this in the parsed_relation_hash because of the 'transformed attributes'
        # For example, MergeRequestDiffFiles exports its diff attribute as utf8_diff. Then,
        # in the create method that attribute is renamed to diff. And because diff is an excluded key,
        # if we clean the excluded keys in the parsed_relation_hash, it will be removed
        # from the object attributes and the export will fail.
        @relation_hash.except!(*excluded_keys)
      end

      # Creates an object from an actual model with name "relation_sym" with params from
      # the relation_hash, updating references with new object IDs, mapping users using
      # the "members_mapper" object, also updating notes if required.
      def create
        return if unknown_service?

        # Do not import legacy triggers
        return if !Feature.enabled?(:use_legacy_pipeline_triggers, @project) && legacy_trigger?

        setup_models

        generate_imported_object
      end

      def self.overrides
        OVERRIDES
      end

      def self.existing_object_check
        EXISTING_OBJECT_CHECK
      end

      private

      def setup_models
        case @relation_name
        when :merge_request_diff_files       then setup_diff
        when :notes                          then setup_note
        end

        update_user_references
        update_project_references
        update_group_references
        remove_duplicate_assignees

        if @relation_name == :'Ci::Pipeline'
          update_merge_request_references
          setup_pipeline
        end

        reset_tokens!
        remove_encrypted_attributes!
      end

      def update_user_references
        USER_REFERENCES.each do |reference|
          if @relation_hash[reference]
            @relation_hash[reference] = @members_mapper.map[@relation_hash[reference]]
          end
        end
      end

      def remove_duplicate_assignees
        return unless @relation_hash['issue_assignees']

        # When an assignee did not exist in the members mapper, the importer is
        # assigned. We only need to assign each user once.
        @relation_hash['issue_assignees'].uniq!(&:user_id)
      end

      def setup_note
        set_note_author
        # attachment is deprecated and note uploads are handled by Markdown uploader
        @relation_hash['attachment'] = nil
      end

      # Sets the author for a note. If the user importing the project
      # has admin access, an actual mapping with new project members
      # will be used. Otherwise, a note stating the original author name
      # is left.
      def set_note_author
        old_author_id = @relation_hash['author_id']
        author = @relation_hash.delete('author')

        update_note_for_missing_author(author['name']) unless has_author?(old_author_id)
      end

      def has_author?(old_author_id)
        admin_user? && @members_mapper.include?(old_author_id)
      end

      def missing_author_note(updated_at, author_name)
        timestamp = updated_at.split('.').first
        "\n\n *By #{author_name} on #{timestamp} (imported from GitLab project)*"
      end

      def generate_imported_object
        if BUILD_MODELS.include?(@relation_name)
          @relation_hash.delete('trace') # old export files have trace
          @relation_hash.delete('token')
          @relation_hash.delete('commands')
          @relation_hash.delete('artifacts_file_store')
          @relation_hash.delete('artifacts_metadata_store')
          @relation_hash.delete('artifacts_size')

          imported_object
        elsif @relation_name == :merge_requests
          MergeRequestParser.new(@project, @relation_hash.delete('diff_head_sha'), imported_object, @relation_hash).parse!
        else
          imported_object
        end
      end

      def update_project_references
        # If source and target are the same, populate them with the new project ID.
        if @relation_hash['source_project_id']
          @relation_hash['source_project_id'] = same_source_and_target? ? @relation_hash['project_id'] : MergeRequestParser::FORKED_PROJECT_ID
        end

        @relation_hash['target_project_id'] = @relation_hash['project_id'] if @relation_hash['target_project_id']
      end

      def same_source_and_target?
        @relation_hash['target_project_id'] && @relation_hash['target_project_id'] == @relation_hash['source_project_id']
      end

      def update_group_references
        return unless self.class.existing_object_check.include?(@relation_name)
        return unless @relation_hash['group_id']

        @relation_hash['group_id'] = @project.namespace_id
      end

      # This code is a workaround for broken project exports that don't
      # export merge requests with CI pipelines (i.e. exports that were
      # generated from
      # https://gitlab.com/gitlab-org/gitlab/merge_requests/17844).
      # This method can be removed in GitLab 12.6.
      def update_merge_request_references
        # If a merge request was properly created, we don't need to fix
        # up this export.
        return if @relation_hash['merge_request']

        merge_request_id = @relation_hash['merge_request_id']

        return unless merge_request_id

        new_merge_request_id = @merge_requests_mapping[merge_request_id]

        return unless new_merge_request_id

        @relation_hash['merge_request_id'] = new_merge_request_id
        parsed_relation_hash['merge_request_id'] = new_merge_request_id
      end

      def reset_tokens!
        return unless Gitlab::ImportExport.reset_tokens? && TOKEN_RESET_MODELS.include?(@relation_name)

        # If we import/export a project to the same instance, tokens will have to be reset.
        # We also have to reset them to avoid issues when the gitlab secrets file cannot be copied across.
        relation_class.attribute_names.select { |name| name.include?('token') }.each do |token|
          @relation_hash[token] = nil
        end
      end

      def remove_encrypted_attributes!
        return unless relation_class.respond_to?(:encrypted_attributes) && relation_class.encrypted_attributes.any?

        relation_class.encrypted_attributes.each_key do |key|
          @relation_hash[key.to_s] = nil
        end
      end

      def relation_class
        @relation_class ||= self.class.relation_class(@relation_name)
      end

      def imported_object
        if existing_or_new_object.respond_to?(:importing)
          existing_or_new_object.importing = true
        end

        existing_or_new_object
      rescue ActiveRecord::RecordNotUnique
        # as the operation is not atomic, retry in the unlikely scenario an INSERT is
        # performed on the same object between the SELECT and the INSERT
        @imported_object_retries += 1
        retry if @imported_object_retries < IMPORTED_OBJECT_MAX_RETRIES
      end

      def update_note_for_missing_author(author_name)
        @relation_hash['note'] = '*Blank note*' if @relation_hash['note'].blank?
        @relation_hash['note'] = "#{@relation_hash['note']}#{missing_author_note(@relation_hash['updated_at'], author_name)}"
      end

      def admin_user?
        @user.admin?
      end

      def parsed_relation_hash
        @parsed_relation_hash ||= Gitlab::ImportExport::AttributeCleaner.clean(relation_hash: @relation_hash,
                                                                               relation_class: relation_class)
      end

      def setup_diff
        @relation_hash['diff'] = @relation_hash.delete('utf8_diff')
      end

      def setup_pipeline
        @relation_hash.fetch('stages', []).each do |stage|
          stage.statuses.each do |status|
            status.pipeline = imported_object
          end
        end
      end

      def existing_or_new_object
        # Only find existing records to avoid mapping tables such as milestones
        # Otherwise always create the record, skipping the extra SELECT clause.
        @existing_or_new_object ||= begin
          if self.class.existing_object_check.include?(@relation_name)
            attribute_hash = attribute_hash_for(['events'])

            existing_object.assign_attributes(attribute_hash) if attribute_hash.any?

            existing_object
          else
            # Because of single-type inheritance, we need to be careful to use the `type` field
            # See https://gitlab.com/gitlab-org/gitlab/issues/34860#note_235321497
            inheritance_column = relation_class.try(:inheritance_column)
            inheritance_attributes = parsed_relation_hash.slice(inheritance_column)
            object = relation_class.new(inheritance_attributes)
            object.assign_attributes(parsed_relation_hash)
            object
          end
        end
      end

      def attribute_hash_for(attributes)
        attributes.inject({}) do |hash, value|
          hash[value] = parsed_relation_hash.delete(value) if parsed_relation_hash[value]
          hash
        end
      end

      def existing_object
        @existing_object ||= find_or_create_object!
      end

      def unknown_service?
        @relation_name == :services && parsed_relation_hash['type'] &&
          !Object.const_defined?(parsed_relation_hash['type'])
      end

      def legacy_trigger?
        @relation_name == :'Ci::Trigger' && @relation_hash['owner_id'].nil?
      end

      def find_or_create_object!
        if UNIQUE_RELATIONS.include?(@relation_name)
          unique_relation_object = relation_class.find_or_create_by(project_id: @project.id)
          unique_relation_object.assign_attributes(parsed_relation_hash)

          return unique_relation_object
        end

        # Can't use IDs as validation exists calling `group` or `project` attributes
        finder_hash = parsed_relation_hash.tap do |hash|
          hash['group'] = @project.group if relation_class.attribute_method?('group_id')
          hash['project'] = @project if relation_class.reflect_on_association(:project)
          hash.delete('project_id')
        end

        GroupProjectObjectBuilder.build(relation_class, finder_hash)
      end
    end
  end
end
