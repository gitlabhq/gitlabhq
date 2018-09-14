module EE
  module Notify
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include ::Emails::AdminNotification
    include ::Emails::CsvExport
    include ::Emails::ServiceDesk
    include ::Emails::Epics

    attr_reader :group

    private

    override :reply_display_name
    def reply_display_name(model)
      return super unless model.is_a?(Epic)

      group.full_name
    end
  end
end
