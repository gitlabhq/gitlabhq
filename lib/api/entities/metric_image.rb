# frozen_string_literal: true

module API
  module Entities
    class MetricImage < Grape::Entity
      expose :id, documentation: { type: 'Integer', example: 23 }
      expose :created_at, documentation: { type: 'DateTime', example: '2020-11-13T00:06:18.084Z' }
      expose :filename, documentation: { type: 'String', example: 'file.png' }
      expose :file_path, documentation: { type: 'String',
                                          example: '/uploads/-/system/alert_metric_image/file/23/file.png' }
      expose :url, documentation: { type: 'String', example: 'https://example.com/metric' }
      expose :url_text, documentation: { type: 'String', example: 'An example metric' }
    end
  end
end
