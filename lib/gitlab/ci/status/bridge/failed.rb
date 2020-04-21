# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      module Bridge
        class Failed < Status::Build::Failed
        end
      end
    end
  end
end
