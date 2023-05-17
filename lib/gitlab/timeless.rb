# frozen_string_literal: true

module Gitlab
  module Timeless
    def self.timeless(model)
      original_record_timestamps = model.record_timestamps
      model.record_timestamps = false

      yield model
    ensure
      model.record_timestamps = original_record_timestamps
    end
  end
end
