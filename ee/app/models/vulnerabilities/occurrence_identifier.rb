# frozen_string_literal: true

module Vulnerabilities
  class OccurrenceIdentifier < ActiveRecord::Base
    self.table_name = "vulnerability_occurrence_identifiers"

    belongs_to :occurrence, class_name: 'Vulnerabilities::Occurrence'
    belongs_to :identifier, class_name: 'Vulnerabilities::Identifier'

    validates :occurrence, presence: true
    validates :identifier, presence: true
    validates :identifier_id, uniqueness: { scope: [:occurrence_id] }
    validates :occurrence_id, uniqueness: true, if: :primary
  end
end
