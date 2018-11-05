# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Extended < SimpleDelegator
        def initialize(status)
          super(@status = status)
        end

        def self.matches?(_subject, _user)
          raise NotImplementedError
        end
      end
    end
  end
end
