# frozen_string_literal: true

# TODO: remove this in 14.7 https://gitlab.com/gitlab-org/gitlab/-/issues/348582
class PagesUpdateConfigurationWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 1

  idempotent!
  feature_category :pages

  def perform(_project_id)
    # Do nothing
  end
end
