# frozen_string_literal: true

module Users
  class DesignatedBeneficiary < ApplicationRecord
    belongs_to :user
  end
end
