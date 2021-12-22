# frozen_string_literal: true

module WorkItems
  class TypePolicy < BasePolicy
    condition(:is_default_type) { @subject.default? }

    rule { is_default_type }.enable :read_work_item_type
  end
end
