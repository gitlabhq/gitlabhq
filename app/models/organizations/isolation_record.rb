# frozen_string_literal: true

module Organizations
  class IsolationRecord < ApplicationRecord
    self.abstract_class = true

    validates :isolated, inclusion: { in: [true, false] }

    def not_isolated?
      !isolated
    end
  end
end
