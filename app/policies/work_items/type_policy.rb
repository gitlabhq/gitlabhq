# frozen_string_literal: true

module WorkItems
  class TypePolicy < BasePolicy
    condition(:type_present) { @subject.present? }

    rule { type_present }.enable :read_work_item_type
  end
end
