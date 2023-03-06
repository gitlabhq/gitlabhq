# frozen_string_literal: true

module Gitlab
  module Loggable
    ANONYMOUS = '<Anonymous>'

    def build_structured_payload(**params)
      { class: self.class.name || ANONYMOUS }.merge(params).stringify_keys
    end
  end
end
