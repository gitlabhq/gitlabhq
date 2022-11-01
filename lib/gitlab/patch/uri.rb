# frozen_string_literal: true

module Gitlab
  module Patch
    module Uri
      module ClassMethods
        def parse(uri)
          raise URI::InvalidURIError, "URI is too long" if uri && uri.to_s.length > 15_000

          super
        end
      end
    end
  end
end
