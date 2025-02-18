# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Project
      class RelationFactory < Base::RelationFactory
        OVERRIDES = { snippets: :project_snippets,
                      commit_notes: 'Note',
                      ci_pipelines: 'Ci::Pipeline',
                      pipelines: 'Ci::Pipeline',
                      stages: 'Ci::Stage',
                      statuses: 'commit_status',
                      triggers: 'Ci::Trigger',
                      pipeline_schedules: 'Ci::PipelineSchedule',
                      builds: 'Ci::Build',
                      bridges: 'Ci::Bridge',
                      runners: 'Ci::Runner',
                      pipeline_metadata: 'Ci::PipelineMetadata',
                      external_pull_request: 'Ci::ExternalPullRequest',
                      external_pull_requests: 'Ci::ExternalPullRequest',
                      hooks: 'ProjectHook',
                      merge_access_levels: 'ProtectedBranch::MergeAccessLevel',
                      push_access_levels: 'ProtectedBranch::PushAccessLevel',
                      create_access_levels: 'ProtectedTag::CreateAccessLevel',
                      design: 'DesignManagement::Design',
                      designs: 'DesignManagement::Design',
                      design_management_repository: 'DesignManagement::Repository',
                      design_management_repository_state: 'Geo::DesignManagementRepositoryState',
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
                      commit_author: 'MergeRequest::DiffCommitUser',
                      committer: 'MergeRequest::DiffCommitUser',
                      merge_request_diff_commits: 'MergeRequestDiffCommit',
                      work_item_type: 'WorkItems::Type',
                      user_contributions: 'User' }.freeze

        BUILD_MODELS = %i[Ci::Build Ci::Bridge commit_status generic_commit_status].freeze

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
          Ci::ExternalPullRequest
          DesignManagement::Design
          MergeRequest::DiffCommitUser
          MergeRequestDiffCommit
          WorkItems::Type
        ].freeze

        RELATIONS_WITH_REWRITABLE_USERNAMES = %i[
          milestones
          milestone
          merge_requests
          merge_request
          issues
          issue
          notes
          note
          epics
          epic
          snippets
          snippet
          WorkItems::Type
        ].freeze

        def create
          @object = super

          # We preload the project, user, and group to re-use objects
          @object = preload_keys(@object, PROJECT_REFERENCES, @importable)
          @object = preload_keys(@object, GROUP_REFERENCES, @importable.group)
          @object = preload_keys(@object, USER_REFERENCES, @user)
        end

        private

        attr_reader :relation_hash, :user

        def invalid_relation?
          # Do not create relation if it is a legacy trigger
          legacy_trigger?
        end

        def setup_models # rubocop:disable Metrics/CyclomaticComplexity -- real sum complexity not as high as rubocop thinks.
          case @relation_name
          when :merge_request_diff_files then setup_diff
          when :note_diff_file then setup_diff
          when :notes, :Note then setup_note
          when :'Ci::Pipeline' then setup_pipeline
          when *BUILD_MODELS then setup_build
          when :issues then setup_work_item
          when :'Ci::PipelineSchedule' then setup_pipeline_schedule
          when :'ProtectedBranch::MergeAccessLevel' then setup_protected_ref_access_level
          when :'ProtectedBranch::PushAccessLevel' then setup_protected_ref_access_level
          when :'ProtectedTag::CreateAccessLevel' then setup_protected_ref_access_level
          when :ApprovalProjectRulesProtectedBranch then setup_merge_approval_protected_branch
          when :releases then setup_release
          when :merge_requests, :MergeRequest, :merge_request then setup_merge_request
          when :approvals then setup_approval
          when :events then setup_event
          end

          update_project_references
          update_group_references

          return unless RELATIONS_WITH_REWRITABLE_USERNAMES.include?(@relation_name) && @rewrite_mentions

          update_username_mentions(@relation_hash)
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
          diff = @relation_hash.delete('diff_export') || @relation_hash.delete('utf8_diff')

          parsed_relation_hash['diff'] = diff.delete("\x00")
        end

        def setup_pipeline
          @relation_hash['status'] = transform_status(@relation_hash['status'])

          @relation_hash.fetch('stages', []).each do |stage|
            stage.status = transform_status(stage.status)

            # old export files have statuses
            stage.statuses.each do |job|
              job.status = transform_status(job.status)
              job.pipeline = imported_object
            end

            stage.builds.each do |job|
              job.status = transform_status(job.status)
              job.pipeline = imported_object
            end

            stage.bridges.each do |job|
              job.status = transform_status(job.status)
              job.pipeline = imported_object
            end

            stage.generic_commit_statuses.each do |job|
              job.status = transform_status(job.status)
              job.pipeline = imported_object
            end
          end
        end

        def setup_work_item
          @relation_hash['relative_position'] = compute_relative_position

          issue_type = @relation_hash.delete('issue_type')
          @relation_hash['work_item_type'] ||= ::WorkItems::Type.default_by_type(issue_type) if issue_type
        end

        def setup_release
          # When author is not present for source release set the author as ghost user.

          if @relation_hash['author_id'].blank?
            @relation_hash['author_id'] = Users::Internal.ghost.id
          end
        end

        def setup_pipeline_schedule
          @relation_hash['active'] = false
          @relation_hash['owner_id'] = @user.id
          @original_user.delete('owner_id') # unset original user to not push placeholder references
        end

        def setup_merge_request
          @relation_hash['merge_when_pipeline_succeeds'] = false
        end

        def setup_approval
          @relation_hash = {} if @relation_hash['user_id'].nil?
        end

        def setup_event
          @relation_hash = {} if @relation_hash['author_id'].nil?
        end

        def setup_protected_ref_access_level
          return if root_group_owner?
          return if @relation_hash['access_level'] == Gitlab::Access::NO_ACCESS
          return if @relation_hash['access_level'] == Gitlab::Access::MAINTAINER

          @relation_hash['access_level'] = Gitlab::Access::MAINTAINER
        end

        def root_group_owner?
          root_ancestor = @importable.root_ancestor

          return false unless root_ancestor.is_a?(::Group)

          root_ancestor.max_member_access_for_user(@user) == Gitlab::Access::OWNER
        end

        def setup_merge_approval_protected_branch
          source_branch_name = @relation_hash.delete('branch_name')
          target_branch = @importable.protected_branches.find_by(name: source_branch_name)

          @relation_hash['protected_branch'] = target_branch
        end

        def compute_relative_position
          return unless max_relative_position

          max_relative_position + ((@relation_index + 1) * Gitlab::RelativePositioning::IDEAL_DISTANCE)
        end

        def max_relative_position
          Rails.cache.fetch("import:#{@importable.model_name.plural}:#{@importable.id}:hierarchy_max_issues_relative_position", expires_in: 24.hours) do
            ::RelativePositioning.mover.context(Issue.in_projects(@importable.root_ancestor.all_projects).first)&.max_relative_position || ::Gitlab::RelativePositioning::START_POSITION
          end
        end

        def legacy_trigger?
          @relation_name == :'Ci::Trigger' && @relation_hash['owner_id'].nil?
        end

        def transform_status(status)
          return 'canceled' if ::Ci::HasStatus::COMPLETED_STATUSES.exclude?(status)

          status
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
