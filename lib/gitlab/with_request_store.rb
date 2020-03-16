# frozen_string_literal: true

module Gitlab
  module WithRequestStore
    def with_request_store
      RequestStore.begin!
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end
  end
end
