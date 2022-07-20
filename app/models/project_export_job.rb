# frozen_string_literal: true

class ProjectExportJob < ApplicationRecord
  belongs_to :project
  has_many :relation_exports, class_name: 'Projects::ImportExport::RelationExport'

  validates :project, :jid, :status, presence: true

  state_machine :status, initial: :queued do
    event :start do
      transition [:queued] => :started
    end

    event :finish do
      transition [:started] => :finished
    end

    event :fail_op do
      transition [:queued, :started] => :failed
    end

    state :queued, value: 0
    state :started, value: 1
    state :finished, value: 2
    state :failed, value: 3
  end
end
