# frozen_string_literal: true

module API
  module Entities
    class MetricImage < Grape::Entity
      expose :id, documentation: { type: 'integer', example: 23 }
      expose :created_at, documentation: { type: 'dateTime', example: '2020-11-13T00:06:18.084Z' }
      expose :filename, documentation: { type: 'string', example: 'file.png' }
      expose :file_path, documentation: { type: 'string',
                                          example: '/uploads/-/system/alert_metric_image/file/23/file.png' }
      expose :url, documentation: { type: 'string', example: 'https://example.com/metric' }
      expose :url_text, documentation: { type: 'string', example: 'An example metric' }
    end
  end
end
