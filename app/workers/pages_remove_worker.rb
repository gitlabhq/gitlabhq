# frozen_string_literal: true

class PagesRemoveWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  feature_category :pages
  loggable_arguments 0

  def perform(project_id)
    project = Project.find_by_id(project_id)
    return unless project

    project.remove_pages
    project.pages_domains.delete_all
  end
end
