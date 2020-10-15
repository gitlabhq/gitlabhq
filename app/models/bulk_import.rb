# frozen_string_literal: true

class BulkImport < ApplicationRecord
  belongs_to :user, optional: false

  has_one :configuration, class_name: 'BulkImports::Configuration'
  has_many :entities, class_name: 'BulkImports::Entity'

  validates :source_type, :status, presence: true

  enum source_type: { gitlab: 0 }

  state_machine :status, initial: :created do
    state :created, value: 0
  end
end
