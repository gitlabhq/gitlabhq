# frozen_string_literal: true

module Pages
  class ResetPagesDefaultDomainRedirectWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    feature_category :pages
    idempotent!

    def handle_event(event)
      project_settings = ProjectSetting.find_by_project_id(event.data['project_id'])

      return unless project_settings
      return unless project_settings.pages_primary_domain
      return unless event.data['domain'] == project_settings.pages_primary_domain

      project_settings.update!(pages_primary_domain: nil)
    end
  end
end
