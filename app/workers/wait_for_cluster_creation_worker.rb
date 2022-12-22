# frozen_string_literal: true

class WaitForClusterCreationWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ClusterQueue

  idempotent!

  def perform(_); end
end
