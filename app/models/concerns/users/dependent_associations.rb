# frozen_string_literal: true

module Users
  module DependentAssociations
    extend ActiveSupport::Concern

    included do
      # rubocop:disable Cop/ActiveRecordDependent -- we need to destroy/nullify records after each user delete.
      has_many :abuse_report_events,
        foreign_key: :user_id,
        class_name: 'ResourceEvents::AbuseReportEvent',
        inverse_of: :user,
        dependent: :nullify

      has_many :authentication_events, dependent: :nullify

      has_many :board_group_recent_visits, dependent: :destroy

      has_many :board_project_recent_visits, dependent: :destroy
      has_many :bulk_import_exports,
        foreign_key: :user_id,
        class_name: 'BulkImports::Export',
        inverse_of: :user,
        dependent: :destroy

      has_many :csv_issue_imports, class_name: 'Issues::CsvImport', dependent: :destroy

      has_many :draft_notes,
        foreign_key: :author_id,
        inverse_of: :author,
        dependent: :destroy

      has_many :group_deletion_schedules,
        foreign_key: :user_id,
        inverse_of: :deleting_user,
        dependent: :destroy

      has_many :group_import_states,
        foreign_key: :user_id,
        inverse_of: :user,
        dependent: :destroy

      has_many :import_failures, dependent: :destroy

      has_many :placeholder_user_import_source_users,
        foreign_key: :placeholder_user_id,
        class_name: 'Import::SourceUser',
        inverse_of: :placeholder_user,
        dependent: :nullify

      has_many :reassign_to_user_import_source_users,
        foreign_key: :reassign_to_user_id,
        class_name: 'Import::SourceUser',
        inverse_of: :reassign_to_user,
        dependent: :nullify

      has_many :reassigned_by_user_import_source_users,
        foreign_key: :reassigned_by_user_id,
        class_name: 'Import::SourceUser',
        inverse_of: :reassigned_by_user,
        dependent: :nullify

      has_many :jira_imports, class_name: 'JiraImportState',
        dependent: :nullify,
        inverse_of: :user

      has_many :list_user_preferences, dependent: :destroy

      has_many :members_deletion_schedules, class_name: 'Members::DeletionSchedule', dependent: :destroy

      has_many :project_export_jobs,
        foreign_key: :user_id,
        inverse_of: :user,
        dependent: :nullify

      has_many :service_desk_custom_email_verifications,
        class_name: 'ServiceDesk::CustomEmailVerification',
        foreign_key: :triggerer_id,
        inverse_of: :triggerer,
        dependent: :nullify

      has_many :ssh_signatures, class_name: 'CommitSignatures::SshSignature', dependent: :nullify

      has_many :work_item_type_user_preferences,
        class_name: 'WorkItems::UserPreference',
        dependent: :destroy

      has_many :protected_tag_create_access_levels, class_name: 'ProtectedTag::CreateAccessLevel',
        dependent: :delete_all

      has_many :packages,
        class_name: 'Packages::Package',
        foreign_key: :creator_id,
        inverse_of: :creator,
        dependent: :nullify

      has_many :composer_packages,
        class_name: 'Packages::Composer::Package',
        foreign_key: :creator_id,
        inverse_of: :creator,
        dependent: :nullify

      has_many :debian_group_distributions,
        class_name: 'Packages::Debian::GroupDistribution',
        foreign_key: :creator_id,
        inverse_of: :creator,
        dependent: :nullify

      has_many :debian_project_distributions,
        class_name: 'Packages::Debian::ProjectDistribution',
        foreign_key: :creator_id,
        inverse_of: :creator,
        dependent: :nullify
      # rubocop:enable Cop/ActiveRecordDependent
    end
  end
end

Users::DependentAssociations.include_mod_with('Users::DependentAssociations')
