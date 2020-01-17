# frozen_string_literal: true

Retriable.configure do |config|
  config.contexts[:relation_import] = {
    tries: ENV.fetch('RELATION_IMPORT_TRIES', 3).to_i,
    base_interval: ENV.fetch('RELATION_IMPORT_BASE_INTERVAL', 0.5).to_f,
    multiplier: ENV.fetch('RELATION_IMPORT_MULTIPLIER', 1.5).to_f,
    rand_factor: ENV.fetch('RELATION_IMPORT_RAND_FACTOR', 0.5).to_f,
    on: Gitlab::ImportExport::ImportFailureService::RETRIABLE_EXCEPTIONS
  }
end
