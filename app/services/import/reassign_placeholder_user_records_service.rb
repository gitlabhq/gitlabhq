# frozen_string_literal: true

module Import
  class ReassignPlaceholderUserRecordsService
    NoReassignToUser = Class.new(StandardError)

    attr_accessor :import_source_user

    def initialize(import_source_user)
      @import_source_user = import_source_user
    end

    def execute
      return unless import_source_user.reassignment_in_progress?

      Import::SourceUserPlaceholderReference.model_groups_for_source_user(import_source_user).each do |reference_group|
        model = reference_group.model
        user_reference_column = reference_group.user_reference_column

        begin
          Import::SourceUserPlaceholderReference.model_relations_for_source_user_reference(
            model: model,
            source_user: import_source_user,
            user_reference_column: user_reference_column
          ) do |model_relation, placeholder_references|
            reassign_placeholder_records_batch(model_relation, placeholder_references, user_reference_column)
          end
        rescue NameError => e
          ::Import::Framework::Logger.error(
            message: "#{model} is not a model, #{user_reference_column} cannot be reassigned.",
            error: e.message,
            source_user_id: import_source_user&.id
          )

          next
        end
      end

      import_source_user.complete!
    end

    private

    def reassign_placeholder_records_batch(model_relation, placeholder_references, user_reference_column)
      ApplicationRecord.transaction do
        model_relation.update_all({ user_reference_column => import_source_user.reassign_to_user_id })
        placeholder_references.delete_all
      end
    rescue ActiveRecord::RecordNotUnique
      placeholder_references.each do |placeholder_reference|
        reassign_placeholder_record(placeholder_reference, user_reference_column)
      end
    end

    def reassign_placeholder_record(placeholder_reference, user_reference_column)
      placeholder_reference.model_record.update!({ user_reference_column => import_source_user.reassign_to_user_id })
      placeholder_reference.destroy!
    rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
      ::Import::Framework::Logger.warn(
        message: "Unable to reassign record, reassigned user is invalid or not unique",
        source_user_id: import_source_user.id
      )
    end
  end
end
