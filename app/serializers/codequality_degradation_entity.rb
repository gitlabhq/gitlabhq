# frozen_string_literal: true

class CodequalityDegradationEntity < Grape::Entity
  expose :description
  expose :fingerprint
  expose :severity do |degradation|
    severity = degradation[:severity]&.downcase

    ::Gitlab::Ci::Reports::CodequalityReports::SEVERITY_PRIORITIES.key?(severity) ? severity : 'unknown'
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
