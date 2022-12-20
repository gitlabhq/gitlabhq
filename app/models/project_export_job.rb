# frozen_string_literal: true

class ProjectExportJob < ApplicationRecord
  include EachBatch

  EXPIRES_IN = 7.days

  belongs_to :project
  has_many :relation_exports, class_name: 'Projects::ImportExport::RelationExport'

  validates :project, :jid, :status, presence: true

  STATUS = {
    queued: 0,
    started: 1,
    finished: 2,
    failed: 3
  }.freeze

  scope :prunable, -> { where("updated_at < ?", EXPIRES_IN.ago) }

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

  class << self
    def prune_expired_jobs
      prunable.each_batch do |relation| # rubocop:disable Style/SymbolProc
        relation.delete_all
      end
    end
  end
end
