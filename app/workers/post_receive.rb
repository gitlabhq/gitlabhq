# frozen_string_literal: true

class PostReceive
  include ApplicationWorker

  idempotent!
  deduplicate :none
  data_consistency :sticky

  sidekiq_options retry: 3
  include Gitlab::Experiment::Dsl
  include ::Gitlab::ExclusiveLeaseHelpers

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  weight 5
  loggable_arguments 0, 1, 2, 3

  def perform(gl_repository, identifier, changes, push_options = {})
    Repositories::PostReceiveWorker.new.perform(gl_repository, identifier, changes, push_options)
  end
end
