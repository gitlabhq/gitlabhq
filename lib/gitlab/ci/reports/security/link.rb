# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Link
          attr_accessor :name, :url

          def initialize(name: nil, url: nil)
            @name = name
            @url = url
          end

          def to_hash
            {
              name: name,
              url: url
            }.compact
          end
        end
      end
    end
  end
end
