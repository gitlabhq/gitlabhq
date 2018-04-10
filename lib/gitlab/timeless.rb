module Gitlab
  module Timeless
    def self.timeless(model, &block)
      original_record_timestamps = model.record_timestamps
      model.record_timestamps = false

      if block.arity.abs == 1
        block.call(model)
      else
        block.call
      end

    ensure
      model.record_timestamps = original_record_timestamps
    end
  end
end
