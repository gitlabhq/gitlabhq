# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Retryable < Status::Build::Retryable
        end
      end
    end
  end
end
