# frozen_string_literal: true

# The BulkImport model links all models required for a bulk import of groups and
# projects to a GitLab instance. It associates the import with the responsible
# user.
class BulkImport < ApplicationRecord
  belongs_to :user, optional: false

  has_one :configuration, class_name: 'BulkImports::Configuration'
  has_many :entities, class_name: 'BulkImports::Entity'

  validates :source_type, :status, presence: true

  enum source_type: { gitlab: 0 }

  state_machine :status, initial: :created do
    state :created, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: -1

    event :start do
      transition created: :started
    end

    event :finish do
      transition started: :finished
    end

    event :fail_op do
      transition any => :failed
    end
  end
end
