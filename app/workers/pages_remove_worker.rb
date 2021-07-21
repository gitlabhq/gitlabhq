# frozen_string_literal: true

# TODO: remove this worker https://gitlab.com/gitlab-org/gitlab/-/issues/320775
class PagesRemoveWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  feature_category :pages
  tags :exclude_from_kubernetes
  loggable_arguments 0

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    project.legacy_remove_pages
  end
end
