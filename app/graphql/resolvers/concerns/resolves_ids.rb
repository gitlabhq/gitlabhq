# frozen_string_literal: true

module ResolvesIds
  extend ActiveSupport::Concern

  def resolve_ids(ids)
    Array.wrap(ids).map do |id|
      next unless id.present?

      id.model_id
    end.compact
  end
end
