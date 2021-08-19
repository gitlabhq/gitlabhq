# frozen_string_literal: true

module ResolvesIds
  extend ActiveSupport::Concern

  def resolve_ids(ids, type)
    Array.wrap(ids).map do |id|
      next unless id.present?

      # TODO: remove this line when the compatibility layer is removed
      # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
      id = type.coerce_isolated_input(id)
      id.model_id
    end.compact
  end
end
