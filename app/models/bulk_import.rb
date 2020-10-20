# frozen_string_literal: true

# The BulkImport import model links together all the models required to for a
# bulk import of groups and projects to a GitLab instance, and associates these
# with the user that initiated the import.
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
