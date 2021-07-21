# frozen_string_literal: true

class PagesUpdateConfigurationWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  idempotent!
  feature_category :pages
  tags :exclude_from_kubernetes

  def self.perform_async(*args)
    return unless ::Settings.pages.local_store.enabled

    super(*args)
  end

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    Projects::UpdatePagesConfigurationService.new(project).execute
  end
end
