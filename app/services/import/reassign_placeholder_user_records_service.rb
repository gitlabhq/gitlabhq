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

      warn_about_any_risky_reassignments

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

    def warn_about_any_risky_reassignments
      warn_about_reassign_to_admin if import_source_user.reassign_to_user.admin? # rubocop:disable Cop/UserAdmin -- Not authentication related
      warn_about_different_contributor_and_importer_hosts if contributor_and_importer_hosts_different?
    end

    def warn_about_different_contributor_and_importer_hosts
      warn_about_risky_reassignment(
        "Reassigning contributions to user with different email host from user who triggered the reassignment"
      )
    end

    def warn_about_reassign_to_admin
      warn_about_risky_reassignment("Reassigning contributions to user with admin privileges")
    end

    def warn_about_risky_reassignment(message)
      ::Import::Framework::Logger.warn(
        message: message,
        namespace: import_source_user.namespace.full_path,
        source_hostname: import_source_user.source_hostname,
        source_user_id: import_source_user.id,
        reassign_to_user_id: import_source_user.reassign_to_user_id,
        reassigned_by_user_id: import_source_user.reassigned_by_user_id
      )
    end

    def contributor_and_importer_hosts_different?
      Mail::Address.new(import_source_user.reassign_to_user.email).domain !=
        Mail::Address.new(import_source_user.reassigned_by_user&.email).domain
    end

    def reassign_placeholder_records_batch(model_relation, placeholder_references, user_reference_column)
      model_relation.klass.transaction do
        model_relation.update_all({ user_reference_column => import_source_user.reassign_to_user_id })
      end
      placeholder_references.delete_all
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
