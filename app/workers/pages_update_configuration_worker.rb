# frozen_string_literal: true

class PagesUpdateConfigurationWorker
  include ApplicationWorker

  idempotent!
  feature_category :pages

  def self.perform_async(*args)
    return unless Feature.enabled?(:pages_update_legacy_storage, default_enabled: true)

    super(*args)
  end

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    Projects::UpdatePagesConfigurationService.new(project).execute
  end
end
