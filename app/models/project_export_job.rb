# frozen_string_literal: true

class ProjectExportJob < ApplicationRecord
  belongs_to :project
  has_many :relation_exports, class_name: 'Projects::ImportExport::RelationExport'

  validates :project, :jid, :status, presence: true

  STATUS = {
    queued: 0,
    started: 1,
    finished: 2,
    failed: 3
  }.freeze

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

    state :queued, value: STATUS[:queued]
    state :started, value: STATUS[:started]
    state :finished, value: STATUS[:finished]
    state :failed, value: STATUS[:failed]
  end
end
