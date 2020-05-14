# frozen_string_literal: true

class Iteration < ApplicationRecord
  include Timebox

  self.table_name = 'sprints'

  STATE_ID_MAP = {
      active: 1,
      closed: 2
  }.with_indifferent_access.freeze

  include AtomicInternalId

  has_many :issues, foreign_key: 'sprint_id'
  has_many :merge_requests, foreign_key: 'sprint_id'

  belongs_to :project
  belongs_to :group

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.iterations&.maximum(:iid) }
  has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.iterations&.maximum(:iid) }

  state_machine :state, initial: :active do
    event :close do
      transition active: :closed
    end

    event :activate do
      transition closed: :active
    end

    state :active, value: Iteration::STATE_ID_MAP[:active]
    state :closed, value: Iteration::STATE_ID_MAP[:closed]
  end
end
