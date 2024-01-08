# frozen_string_literal: true

module Namespaces
  class Descendants < ApplicationRecord
    self.table_name = :namespace_descendants

    belongs_to :namespace

    validates :namespace_id, uniqueness: true
  end
end
