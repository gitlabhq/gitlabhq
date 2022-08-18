# frozen_string_literal: true

module Issues
  class PrepareImportCsvService < Import::PrepareService
    extend ::Gitlab::Utils::Override

    private

    override :worker
    def worker
      ImportIssuesCsvWorker
    end

    override :success_message
    def success_message
      _("Your issues are being imported. Once finished, you'll get a confirmation email.")
    end
  end
end
