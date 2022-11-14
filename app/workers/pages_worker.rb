# frozen_string_literal: true

class PagesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  feature_category :pages
  loggable_arguments 0, 1
  worker_resource_boundary :cpu

  def perform(action, *arg)
    deploy(*arg) if action == 'deploy'
  end

  def deploy(build_id)
    build = Ci::Build.find_by_id(build_id)

    Projects::UpdatePagesService.new(build.project, build).execute
  end
end
