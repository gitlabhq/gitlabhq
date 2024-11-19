# frozen_string_literal: true

module AntiAbuse
  module Reports
    class LabelPolicy < BasePolicy
      rule { admin }.policy do
        enable :read_label
      end
    end
  end
end
