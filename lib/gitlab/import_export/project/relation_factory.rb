# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationFactory < Base::RelationFactory
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
                      design: 'DesignManagement::Design',
                      designs: 'DesignManagement::Design',
                      design_versions: 'DesignManagement::Version',
                      actions: 'DesignManagement::Action',
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
                      metrics_setting: 'ProjectMetricsSetting',
                      commit_author: 'MergeRequest::DiffCommitUser',
                      committer: 'MergeRequest::DiffCommitUser' }.freeze

        BUILD_MODELS = %i[Ci::Build commit_status].freeze

        GROUP_REFERENCES = %w[group_id].freeze

        PROJECT_REFERENCES = %w[project_id source_project_id target_project_id].freeze

        EXISTING_OBJECT_RELATIONS = %i[
          milestone
          milestones
          label
          labels
          project_label
          project_labels
          group_label
          group_labels
          project_feature
          merge_request
          epic
          ProjectCiCdSetting
          container_expiration_policy
          external_pull_request
          external_pull_requests
          DesignManagement::Design
          MergeRequest::DiffCommitUser
        ].freeze

        def create
          @object = super

          # We preload the project, user, and group to re-use objects
          @object = preload_keys(@object, PROJECT_REFERENCES, @importable)
          @object = preload_keys(@object, GROUP_REFERENCES, @importable.group)
          @object = preload_keys(@object, USER_REFERENCES, @user)
        end

        private

        def invalid_relation?
          # Do not create relation if it is a legacy trigger
          legacy_trigger?
        end

        def setup_models
          case @relation_name
          when :merge_request_diff_files then setup_diff
          when :notes then setup_note
          when :'Ci::Pipeline' then setup_pipeline
          when *BUILD_MODELS then setup_build
          when :issues then setup_issue
          end

          update_project_references
          update_group_references
        end

        def generate_imported_object
          if @relation_name == :merge_requests
            MergeRequestParser.new(@importable, @relation_hash.delete('diff_head_sha'), super, @relation_hash).parse!
          else
            super
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
          return unless existing_object?
          return unless @relation_hash['group_id']

          @relation_hash['group_id'] = @importable.namespace_id
        end

        def setup_build
          @relation_hash.delete('trace') # old export files have trace
          @relation_hash.delete('token')
          @relation_hash.delete('commands')
          @relation_hash.delete('artifacts_file_store')
          @relation_hash.delete('artifacts_metadata_store')
          @relation_hash.delete('artifacts_size')
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

        def setup_issue
          @relation_hash['relative_position'] = compute_relative_position
        end

        def compute_relative_position
          return unless max_relative_position

          max_relative_position + (@relation_index + 1) * Gitlab::RelativePositioning::IDEAL_DISTANCE
        end

        def max_relative_position
          Rails.cache.fetch("import:#{@importable.model_name.plural}:#{@importable.id}:hierarchy_max_issues_relative_position", expires_in: 24.hours) do
            ::RelativePositioning.mover.context(Issue.in_projects(@importable.root_ancestor.all_projects).first)&.max_relative_position || ::Gitlab::RelativePositioning::START_POSITION
          end
        end

        def legacy_trigger?
          @relation_name == :'Ci::Trigger' && @relation_hash['owner_id'].nil?
        end

        def preload_keys(object, references, value)
          return object unless value

          references.each do |key|
            attribute = "#{key.delete_suffix('_id')}=".to_sym
            next unless object.respond_to?(key) && object.respond_to?(attribute)

            if object.read_attribute(key) == value&.id
              object.public_send(attribute, value) # rubocop:disable GitlabSecurity/PublicSend
            end
          end

          object
        end
      end
    end
  end
end

Gitlab::ImportExport::Project::RelationFactory.prepend_mod_with('Gitlab::ImportExport::Project::RelationFactory')
