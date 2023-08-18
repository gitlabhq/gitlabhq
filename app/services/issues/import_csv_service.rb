# frozen_string_literal: true

module Issues
  class ImportCsvService < Issuable::ImportCsv::BaseService
    def execute
      record_import_attempt

      super
    end

    def email_results_to_user
      Notify.import_issues_csv_email(user.id, project.id, results).deliver_later
    end

    private

    def create_object(attributes)
      super[:issue]
    end

    def create_object_class
      Issues::CreateService
    end

    def extra_create_service_params
      { perform_spam_check: perform_spam_check? }
    end

    def perform_spam_check?
      !user.can_admin_all_resources?
    end

    def record_import_attempt
      Issues::CsvImport.create!(user: user, project: project)
    end
  end
end

Issues::ImportCsvService.prepend_mod
