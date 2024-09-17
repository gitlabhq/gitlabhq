# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Sbom
        class License
          attr_accessor :id, :name, :url

          def initialize(id: nil, name: nil, url: nil)
            @id = id
            @name = name
            @url = url
          end
        end
      end
    end
  end
end
