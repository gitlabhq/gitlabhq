# frozen_string_literal: true

class MergeRequestMetricsEntity < Grape::Entity
  format_with(:iso8601) do |item|
    item.try(:iso8601)
  end

  expose :latest_closed_at, as: :closed_at, format_with: :iso8601
  expose :merged_at, format_with: :iso8601
  expose :latest_closed_by, as: :closed_by, using: UserEntity
  expose :merged_by, using: UserEntity
end
