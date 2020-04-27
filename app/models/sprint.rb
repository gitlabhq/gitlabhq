# frozen_string_literal: true

class Sprint < ApplicationRecord
  STATE_ID_MAP = {
      active: 1,
      closed: 2
  }.with_indifferent_access.freeze

  include AtomicInternalId

  has_many :issues
  has_many :merge_requests

  belongs_to :project
  belongs_to :group

  has_internal_id :iid, scope: :project, init: ->(s) { s&.project&.sprints&.maximum(:iid) }
  has_internal_id :iid, scope: :group, init: ->(s) { s&.group&.sprints&.maximum(:iid) }
end
