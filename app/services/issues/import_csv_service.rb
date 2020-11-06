# frozen_string_literal: true

module Issues
  class ImportCsvService < Issuable::ImportCsv::BaseService
    def execute
      record_import_attempt

      super
    end

    def email_results_to_user
      Notify.import_issues_csv_email(@user.id, @project.id, @results).deliver_later
    end

    private

    def create_issuable_class
      Issues::CreateService
    end

    def record_import_attempt
      Issues::CsvImport.create!(user: @user, project: @project)
    end
  end
end
