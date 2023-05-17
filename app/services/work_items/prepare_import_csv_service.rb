# frozen_string_literal: true

module WorkItems
  class PrepareImportCsvService < Import::PrepareService
    extend ::Gitlab::Utils::Override

    private

    override :worker
    def worker
      ImportWorkItemsCsvWorker
    end

    override :success_message
    def success_message
      _("Your work items are being imported. Once finished, you'll receive a confirmation email.")
    end
  end
end
