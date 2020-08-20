# frozen_string_literal: true

class PagesUpdateConfigurationWorker
  include ApplicationWorker

  idempotent!
  feature_category :pages

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    result = Projects::UpdatePagesConfigurationService.new(project).execute

    # The ConfigurationService swallows all exceptions and wraps them in a status
    # we need to keep this while the feature flag still allows running this
    # service within a request.
    # But we might as well take advantage of sidekiq retries here.
    # We should let the service raise after we remove the feature flag
    # https://gitlab.com/gitlab-org/gitlab/-/issues/230695
    raise result[:exception] if result[:exception]
  end
end
