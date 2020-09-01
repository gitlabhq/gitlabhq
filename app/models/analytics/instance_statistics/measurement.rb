# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    class Measurement < ApplicationRecord
      enum identifier: { projects: 1, users: 2 }

      validates :recorded_at, :identifier, :count, presence: true
      validates :recorded_at, uniqueness: { scope: :identifier }
    end
  end
end
