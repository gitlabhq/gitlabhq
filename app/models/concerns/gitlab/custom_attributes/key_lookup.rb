# frozen_string_literal: true

module Gitlab
  module CustomAttributes
    module KeyLookup
      extend ActiveSupport::Concern

      included do
        scope :by_key, ->(key) { where(key: key) }
      end

      class_methods do
        def find_or_initialize_by_key(key)
          by_key(key).first_or_initialize(key: key)
        end
      end
    end
  end
end
