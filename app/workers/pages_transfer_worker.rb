# frozen_string_literal: true

class PagesTransferWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  TransferFailedError = Class.new(StandardError)

  feature_category :pages
  loggable_arguments 0, 1

  def perform(method, args)
    # noop
    # This worker is not necessary anymore and will be removed
    # https://gitlab.com/gitlab-org/gitlab/-/issues/340616
  end
end
