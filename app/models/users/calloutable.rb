# frozen_string_literal: true

module Users
  module Calloutable
    extend ActiveSupport::Concern

    included do
      belongs_to :user

      validates :user, presence: true
    end

    def dismissed_after?(dismissed_after)
      dismissed_at > dismissed_after
    end
  end
end
