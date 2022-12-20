# frozen_string_literal: true

module Gitlab
  module Timeless
    def self.timeless(model, &block)
      original_record_timestamps = model.record_timestamps
      model.record_timestamps = false

      # negative arity means arguments are optional
      if block.arity == 1 || block.arity < 0
        yield(model)
      else
        yield
      end

    ensure
      model.record_timestamps = original_record_timestamps
    end
  end
end
