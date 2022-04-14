# frozen_string_literal: true

module API
  module Entities
    class MetricImage < Grape::Entity
      expose :id, :created_at, :filename, :file_path, :url, :url_text
    end
  end
end
