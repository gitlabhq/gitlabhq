module EE
  module Notify
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    # We need to put includes in prepended block due to the magical
    # interaction between ActiveSupport::Concern and ActionMailer::Base
    # See https://gitlab.com/gitlab-org/gitlab-ee/issues/7846
    prepended do
      include ::Emails::AdminNotification
      include ::Emails::CsvExport
      include ::Emails::ServiceDesk
      include ::Emails::Epics
    end

    attr_reader :group

    private

    override :reply_display_name
    def reply_display_name(model)
      return super unless model.is_a?(Epic)

      group.full_name
    end
  end
end
