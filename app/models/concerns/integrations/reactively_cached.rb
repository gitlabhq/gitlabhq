# frozen_string_literal: true

module Integrations
  module ReactivelyCached
    extend ActiveSupport::Concern

    included do
      include ::ReactiveCaching

      # Default cache key: class name + project_id
      self.reactive_cache_key = ->(integration) { [integration.class.model_name.singular, integration.project_id] }
      self.reactive_cache_work_type = :external_dependency
    end
  end
end
