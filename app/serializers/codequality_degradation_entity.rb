# frozen_string_literal: true

class CodequalityDegradationEntity < Grape::Entity
  expose :description
  expose :fingerprint, if: ->(_, options) do
    Feature.enabled?(:sast_reports_in_inline_diff, options[:request]&.project)
  end
  expose :severity do |degradation|
    degradation.dig(:severity)&.downcase
  end

  expose :file_path do |degradation|
    degradation.dig(:location, :path)
  end

  expose :line do |degradation|
    degradation.dig(:location, :lines, :begin) || degradation.dig(:location, :positions, :begin, :line)
  end

  expose :web_url

  expose :engine_name
end
