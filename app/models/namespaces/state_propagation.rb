# frozen_string_literal: true

module Namespaces
  class StatePropagation < ApplicationRecord
    self.table_name = 'namespace_state_propagations'

    belongs_to :namespace, class_name: 'Namespace', optional: false

    enum :status, { pending: 0, processing: 1 }, prefix: true
    enum :source_state, Namespace.states, prefix: true
    enum :target_state, Namespace.states, prefix: true

    validates :source_state, presence: true
    validates :target_state, presence: true
    validates :status, presence: true

    scope :pending, -> { status_pending }
    scope :processing, -> { status_processing }
    scope :order_by_created_at_asc, -> { order(created_at: :asc) }
  end
end
