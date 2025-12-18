# frozen_string_literal: true

module API
  module Entities
    module Releases
      class Evidence < Grape::Entity
        include ::API::Helpers::Presentable

        expose :sha, documentation: { type: 'String', example: '760d6cdfb0879c3ffedec13af470e0f71cf52c6cde4d' }
        expose :filepath, documentation: { type: 'String', example: 'https://gitlab.example.com/root/app/-/releases/v1.0/evidence.json' }
        expose :collected_at, documentation: { type: 'DateTime', example: '2019-01-03T01:56:19.539Z' }
      end
    end
  end
end
