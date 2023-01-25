# frozen_string_literal: true

module WebHooks
  module Unstoppable
    extend ActiveSupport::Concern

    included do
      scope :executable, -> { all }

      scope :disabled, -> { none }
    end

    def executable?
      true
    end

    def temporarily_disabled?
      false
    end

    def permanently_disabled?
      false
    end

    def alert_status
      :executable
    end
  end
end
