# frozen_string_literal: true

class CodequalityDegradationEntity < Grape::Entity
  expose :description
  expose :severity

  expose :file_path do |degradation|
    degradation.dig(:location, :path)
  end

  expose :line do |degradation|
    degradation.dig(:location, :lines, :begin) || degradation.dig(:location, :positions, :begin, :line)
  end
end
