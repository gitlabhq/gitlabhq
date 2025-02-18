# frozen_string_literal: true

module Gitlab
  module ImportExport
    module Base
      class RelationFactory
        include Gitlab::Utils::StrongMemoize
        include Import::UsernameMentionRewriter

        IMPORTED_OBJECT_MAX_RETRIES = 5

        OVERRIDES = { user_contributions: :user, merge_schedule: 'MergeRequests::MergeSchedule' }.freeze
        EXISTING_OBJECT_RELATIONS = %i[].freeze

        # This represents all relations that have unique key on `project_id` or `group_id`
        UNIQUE_RELATIONS = %i[].freeze

        USER_REFERENCES = %w[
          author_id
          assignee_id
          updated_by_id
          merged_by_id
          latest_closed_by_id
          user_id
          created_by_id
          last_edited_by_id
          merge_user_id
          resolved_by_id
          closed_by_id
          owner_id
        ].freeze

        TOKEN_RESET_MODELS = %i[Project Namespace Group Ci::Trigger Ci::Build Ci::Runner ProjectHook ErrorTracking::ProjectErrorTrackingSetting].freeze

        attr_reader :relation_name, :relation_hash, :importable

        def self.create(*args, **kwargs)
          new(*args, **kwargs).create
        end

        def self.relation_class(relation_name)
          # There are scenarios where the model is pluralized (e.g.
          # MergeRequest::Metrics), and we don't want to force it to singular
          # with #classify.
          overridden_relation = OVERRIDES.with_indifferent_access[relation_name]
          relation_name = overridden_relation if overridden_relation

          relation_name.to_s.classify.constantize
        rescue NameError
          relation_name.to_s.constantize
        end

        # rubocop:disable Metrics/ParameterLists -- Keyword arguments are not adding complexity to initializer
        def initialize(relation_sym:, relation_index:, relation_hash:, members_mapper:, object_builder:, user:, importable:, import_source:, excluded_keys: [], original_users_map: nil, rewrite_mentions: false)
          @relation_sym = relation_sym
          @relation_name = self.class.overrides[relation_sym]&.to_sym || relation_sym
          @relation_index = relation_index
          @relation_hash = relation_hash.except('noteable_id')
          @members_mapper = members_mapper
          @object_builder = object_builder
          @user = user
          @importable = importable
          @import_source = import_source
          @imported_object_retries = 0
          @relation_hash[importable_column_name] = @importable.id
          @original_user = {}
          @original_users_map = original_users_map
          @rewrite_mentions = rewrite_mentions

          # Remove excluded keys from relation_hash
          # We don't do this in the parsed_relation_hash because of the 'transformed attributes'
          # For example, MergeRequestDiffFiles exports its diff attribute as utf8_diff. Then,
          # in the create method that attribute is renamed to diff. And because diff is an excluded key,
          # if we clean the excluded keys in the parsed_relation_hash, it will be removed
          # from the object attributes and the export will fail.
          @relation_hash.except!(*excluded_keys)
        end
        # rubocop:enable Metrics/ParameterLists

        # Creates an object from an actual model with name "relation_sym" with params from
        # the relation_hash, updating references with new object IDs, mapping users using
        # the "members_mapper" object, also updating notes if required.
        def create
          return @relation_hash if author_relation?
          return if invalid_relation? || predefined_relation?

          setup_base_models
          setup_models

          return if @relation_hash.empty?

          generate_imported_object
        end

        def self.overrides
          self::OVERRIDES
        end

        def self.existing_object_relations
          self::EXISTING_OBJECT_RELATIONS
        end

        private

        def invalid_relation?
          false
        end

        def predefined_relation?
          relation_class.try(:predefined_id?, @relation_hash['id'])
        end

        def author_relation?
          @relation_name == :author
        end

        def setup_models
          raise NotImplementedError
        end

        def unique_relations
          # define in sub-class if any
          self.class::UNIQUE_RELATIONS
        end

        def setup_base_models
          update_user_references
          remove_duplicate_assignees
          reset_tokens!
          remove_encrypted_attributes!
        end

        def update_user_references
          self.class::USER_REFERENCES.each do |reference|
            if @relation_hash[reference]
              @original_user[reference] = @relation_hash[reference]
              @relation_hash[reference] = @members_mapper.map[@relation_hash[reference]]
            end
          end
        end

        # When an assignee (or any other listed association) did not exist in the members mapper, the importer is
        # assigned. We only need to assign each user once.
        def remove_duplicate_assignees
          associations = %w[issue_assignees merge_request_assignees merge_request_reviewers approvals]

          associations.each do |association|
            next unless @relation_hash.key?(association)
            next unless @relation_hash[association].is_a?(Array)
            next if @relation_hash[association].empty?

            @relation_hash[association].select! { |record| record.respond_to?(:user_id) }
            @relation_hash[association].uniq!(&:user_id)
          end
        end

        def generate_imported_object
          imported_object
        end

        def reset_tokens!
          return unless Gitlab::ImportExport.reset_tokens? && self.class::TOKEN_RESET_MODELS.include?(@relation_name)

          # If we import/export to the same instance, tokens will have to be reset.
          # We also have to reset them to avoid issues when the gitlab secrets file cannot be copied across.
          relation_class.attribute_names.select { |name| name.include?('token') }.each do |token|
            @relation_hash[token] = nil
          end
        end

        def remove_encrypted_attributes!
          return unless relation_class.respond_to?(:attr_encrypted_attributes) && relation_class.attr_encrypted_attributes.any?

          relation_class.attr_encrypted_attributes.each_key do |key|
            @relation_hash[key.to_s] = nil
          end
        end

        def relation_class
          @relation_class ||= self.class.relation_class(@relation_name)
        end

        def importable_column_name
          importable_class_name.concat('_id')
        end

        def importable_class_name
          @importable.class.to_s.downcase
        end

        def imported_object
          if existing_or_new_object.respond_to?(:importing)
            existing_or_new_object.importing = true
          end

          if existing_or_new_object.respond_to?(:imported_from)
            existing_or_new_object.imported_from = @import_source
          end

          if @original_users_map.is_a?(Hash) && @original_user.present?
            @original_users_map[existing_or_new_object] = @original_user
          end

          existing_or_new_object
        rescue ActiveRecord::RecordNotUnique
          # as the operation is not atomic, retry in the unlikely scenario an INSERT is
          # performed on the same object between the SELECT and the INSERT
          @imported_object_retries += 1
          retry if @imported_object_retries < IMPORTED_OBJECT_MAX_RETRIES
        end

        def parsed_relation_hash
          strong_memoize(:parsed_relation_hash) do
            if use_attributes_permitter? && attributes_permitter.permitted_attributes_defined?(@relation_sym)
              attributes_permitter.permit(@relation_sym, @relation_hash)
            else
              Gitlab::ImportExport::AttributeCleaner.clean(relation_hash: @relation_hash, relation_class: relation_class)
            end
          end
        end

        def attributes_permitter
          @attributes_permitter ||= Gitlab::ImportExport::AttributesPermitter.new
        end

        def use_attributes_permitter?
          true
        end

        def existing_or_new_object
          # Only find existing records to avoid mapping tables such as milestones
          # Otherwise always create the record, skipping the extra SELECT clause.
          @existing_or_new_object ||= if existing_object?
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

        def attribute_hash_for(attributes)
          attributes.each_with_object({}) do |hash, value|
            hash[value] = parsed_relation_hash.delete(value) if parsed_relation_hash[value]
            hash
          end
        end

        def existing_object
          @existing_object ||= find_or_create_object!
        end

        def unique_relation_object
          unique_relation_object = relation_class.find_or_create_by(importable_column_name => @importable.id)
          unique_relation_object.assign_attributes(parsed_relation_hash)
          unique_relation_object
        end

        def find_or_create_object!
          return unique_relation_object if unique_relation?

          # Can't use IDs as validation exists calling `group` or `project` attributes
          finder_hash = parsed_relation_hash.tap do |hash|
            if relation_class.attribute_method?('group_id') && @importable.is_a?(::Project)
              hash['group'] = @importable.group
            end

            hash[importable_class_name] = @importable if relation_class.reflect_on_association(importable_class_name.to_sym)
            hash.delete(importable_column_name)
          end

          @object_builder.build(relation_class, finder_hash)
        end

        def setup_note
          set_note_author
          # attachment is deprecated and note uploads are handled by Markdown uploader
          @relation_hash['attachment'] = nil

          setup_diff_note
        end

        def setup_diff_note
          return unless @relation_hash['type'] == 'DiffNote'

          update_diff_note_position('position')
          update_diff_note_position('original_position')
          update_diff_note_position('change_position')
        end

        def update_diff_note_position(position)
          return unless @relation_hash[position]
          return unless @relation_hash.dig(position, 'line_range', 'start_line_code')

          line_range = @relation_hash[position].delete('line_range')
          start_lines = line_range['start_line_code'].split('_').map(&:to_i)
          end_lines = line_range['end_line_code'].split('_').map(&:to_i)

          @relation_hash[position]['line_range'] = {
            'start' => {
              'line_code' => line_range['start_line_code'],
              'type' => line_range['start_line_type'],
              'old_line' => start_lines[1] == 0 ? nil : start_lines[1].to_i,
              'new_line' => start_lines[2] == 0 ? nil : start_lines[2].to_i
            },
            'end' => {
              'line_code' => line_range['end_line_code'],
              'type' => line_range['end_line_type'],
              'old_line' => end_lines[1] == 0 ? nil : end_lines[1].to_i,
              'new_line' => end_lines[2] == 0 ? nil : end_lines[2].to_i
            }
          }
        end

        # Sets the author for a note. If the user importing the project
        # has admin access, an actual mapping with new project members
        # will be used. Otherwise, a note stating the original author name
        # is left.
        def set_note_author
          old_author_id = @original_user['author_id']
          author = @relation_hash.delete('author')

          unless @members_mapper.include?(old_author_id)
            @relation_hash['note'] = "%{note}\n\n %{missing_author_note}" % {
              note: @relation_hash['note'].presence || '*Blank note*',
              missing_author_note: missing_author_note(@relation_hash['updated_at'], author['name'])
            }
          end
        end

        def missing_author_note(updated_at, author_name)
          timestamp = updated_at.split('.').first
          "*By #{author_name} on #{timestamp}*"
        end

        def existing_object?
          strong_memoize(:_existing_object) do
            self.class.existing_object_relations.include?(@relation_name) ||
              self.class.existing_object_relations.include?(@relation_sym) ||
              unique_relation?
          end
        end

        def unique_relation?
          # this guard is necessary because
          # when multiple approval_project_rules_protected_branch referenced the same protected branch
          # or approval_project_rules_user referenced the same user
          # the different instances were squashed into one
          # because this method returned true for reason that needs investigation
          return if @relation_sym == :approval_rules

          strong_memoize(:unique_relation) do
            importable_foreign_key.present? &&
              (has_unique_index_on_importable_fk? || uses_importable_fk_as_primary_key?)
          end
        end

        def has_unique_index_on_importable_fk?
          cache = cached_has_unique_index_on_importable_fk
          table_name = relation_class.table_name
          return cache[table_name] if cache.has_key?(table_name)

          index_exists =
            relation_class.connection.index_exists?(
              relation_class.table_name,
              importable_foreign_key,
              unique: true)

          cache[table_name] = index_exists
        end

        # Avoid unnecessary DB requests
        def cached_has_unique_index_on_importable_fk
          Thread.current[:cached_has_unique_index_on_importable_fk] ||= {}
        end

        def uses_importable_fk_as_primary_key?
          relation_class.primary_key == importable_foreign_key
        end

        def importable_foreign_key
          relation_class.reflect_on_association(importable_class_name.to_sym)&.foreign_key
        end
      end
    end
  end
end
