# frozen_string_literal: true

class Namespace::AggregationSchedule < ApplicationRecord
  self.primary_key = :namespace_id

  belongs_to :namespace
end
