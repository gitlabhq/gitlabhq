# frozen_string_literal: true

module ReactiveService
  extend ActiveSupport::Concern

  included do
    include ReactiveCaching

    # Default cache key: class name + project_id
    self.reactive_cache_key = ->(service) { [service.class.model_name.singular, service.project_id] }
  end
end
