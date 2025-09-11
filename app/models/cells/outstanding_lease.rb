# frozen_string_literal: true

module Cells
  class OutstandingLease < ApplicationRecord
    self.primary_key = :uuid
  end
end
