# frozen_string_literal: true

module EE
  module PolicyCheckable
    def auditor?
      false
    end

    def support_bot?
      false
    end
  end
end
