module Gitlab
  module ImportExport
    class RelationFactory
      OVERRIDES = { snippets: :project_snippets,
                    pipelines: 'Ci::Pipeline',
                    stages: 'Ci::Stage',
                    statuses: 'commit_status',
                    triggers: 'Ci::Trigger',
                    pipeline_schedules: 'Ci::PipelineSchedule',
                    builds: 'Ci::Build',
                    hooks: 'ProjectHook',
                    merge_access_levels: 'ProtectedBranch::MergeAccessLevel',
                    push_access_levels: 'ProtectedBranch::PushAccessLevel',
                    create_access_levels: 'ProtectedTag::CreateAccessLevel',
                    labels: :project_labels,
                    priorities: :label_priorities,
                    auto_devops: :project_auto_devops,
                    label: :project_label,
                    custom_attributes: 'ProjectCustomAttribute',
                    project_badges: 'Badge' }.freeze

      USER_REFERENCES = %w[author_id assignee_id updated_by_id user_id created_by_id last_edited_by_id merge_user_id resolved_by_id closed_by_id].freeze

      PROJECT_REFERENCES = %w[project_id source_project_id target_project_id].freeze

      BUILD_MODELS = %w[Ci::Build commit_status].freeze

      IMPORTED_OBJECT_MAX_RETRIES = 5.freeze

      EXISTING_OBJECT_CHECK = %i[milestone milestones label labels project_label project_labels group_label group_labels].freeze

      TOKEN_RESET_MODELS = %w[Ci::Trigger Ci::Build ProjectHook].freeze

      def self.create(*args)
        new(*args).create
      end

      def initialize(relation_sym:, relation_hash:, members_mapper:, user:, project:)
        @relation_name = OVERRIDES[relation_sym] || relation_sym
        @relation_hash = relation_hash.except('noteable_id')
        @members_mapper = members_mapper
        @user = user
        @project = project
        @imported_object_retries = 0
      end

      # Creates an object from an actual model with name "relation_sym" with params from
      # the relation_hash, updating references with new object IDs, mapping users using
      # the "members_mapper" object, also updating notes if required.
      def create
        return nil if unknown_service?

        setup_models

        generate_imported_object
      end

      private

      def setup_models
        case @relation_name
        when :merge_request_diff_files       then setup_diff
        when :notes                          then setup_note
        when :project_label, :project_labels then setup_label
        when :milestone, :milestones         then setup_milestone
        when 'Ci::Pipeline'                  then setup_pipeline
        else
          @relation_hash['project_id'] = @project.id
        end

        update_user_references
        update_project_references
        remove_duplicate_assignees

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

          imported_object
        elsif @relation_name == :merge_requests
          MergeRequestParser.new(@project, @relation_hash.delete('diff_head_sha'), imported_object, @relation_hash).parse!
        else
          imported_object
        end
      end

      def update_project_references
        project_id = @relation_hash.delete('project_id')

        # If source and target are the same, populate them with the new project ID.
        if @relation_hash['source_project_id']
          @relation_hash['source_project_id'] = same_source_and_target? ? project_id : MergeRequestParser::FORKED_PROJECT_ID
        end

        # project_id may not be part of the export, but we always need to populate it if required.
        @relation_hash['project_id'] = project_id
        @relation_hash['target_project_id'] = project_id if @relation_hash['target_project_id']
      end

      def same_source_and_target?
        @relation_hash['target_project_id'] && @relation_hash['target_project_id'] == @relation_hash['source_project_id']
      end

      def setup_label
        # If there's no group, move the label to a project label
        if @relation_hash['type'] == 'GroupLabel' && @relation_hash['group_id']
          @relation_hash['project_id'] = nil
          @relation_name = :group_label
        else
          @relation_hash['group_id'] = nil
          @relation_hash['type'] = 'ProjectLabel'
        end
      end

      def setup_milestone
        if @relation_hash['group_id']
          @relation_hash['group_id'] = @project.group.id
        else
          @relation_hash['project_id'] = @project.id
        end
      end

      def reset_tokens!
        return unless Gitlab::ImportExport.reset_tokens? && TOKEN_RESET_MODELS.include?(@relation_name.to_s)

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
        @relation_class ||= @relation_name.to_s.classify.constantize
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
        @relation_hash['note'] += missing_author_note(@relation_hash['updated_at'], author_name)
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
        @relation_hash.fetch('stages').each do |stage|
          stage.statuses.each do |status|
            status.pipeline = imported_object
          end
        end
      end

      def existing_or_new_object
        # Only find existing records to avoid mapping tables such as milestones
        # Otherwise always create the record, skipping the extra SELECT clause.
        @existing_or_new_object ||= begin
          if EXISTING_OBJECT_CHECK.include?(@relation_name)
            attribute_hash = attribute_hash_for(['events'])

            existing_object.assign_attributes(attribute_hash) if attribute_hash.any?

            existing_object
          else
            relation_class.new(parsed_relation_hash)
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
        @existing_object ||=
          begin
            existing_object = find_or_create_object!

            # Done in two steps, as MySQL behaves differently than PostgreSQL using
            # the +find_or_create_by+ method and does not return the ID the second time.
            existing_object.update!(parsed_relation_hash)
            existing_object
          end
      end

      def unknown_service?
        @relation_name == :services && parsed_relation_hash['type'] &&
          !Object.const_defined?(parsed_relation_hash['type'])
      end

      def find_or_create_object!
        finder_attributes = if @relation_name == :group_label
                              %w[title group_id]
                            elsif parsed_relation_hash['project_id']
                              %w[title project_id]
                            else
                              %w[title group_id]
                            end

        finder_hash = parsed_relation_hash.slice(*finder_attributes)

        if label?
          label = relation_class.find_or_initialize_by(finder_hash)
          parsed_relation_hash.delete('priorities') if label.persisted?

          label.save!
          label
        else
          relation_class.find_or_create_by(finder_hash)
        end
      end

      def label?
        @relation_name.to_s.include?('label')
      end
    end
  end
end
