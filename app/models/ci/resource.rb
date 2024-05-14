# frozen_string_literal: true

module Ci
  class Resource < Ci::ApplicationRecord
    belongs_to :resource_group, class_name: 'Ci::ResourceGroup', inverse_of: :resources
    belongs_to :processable, class_name: 'Ci::Processable', foreign_key: 'build_id', inverse_of: :resource

    scope :free, -> { where(processable: nil) }
    scope :retained, -> { where.not(processable: nil) }
    scope :retained_by, ->(processable) { where(processable: processable) }

    class << self
      # In some cases, state machine hooks in `Ci::Build` are skipped
      # even if the job status transitions to a complete state.
      # For example, `Ci::Build#doom!` (a.k.a `data_integrity_failure`) doesn't execute state machine hooks.
      # To handle these edge cases, we check the staleness of the jobs that currently
      # assigned to the resources, and release if it's stale.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/335537#note_632925914 for more information.
      def stale_processables
        Ci::Processable.where(id: retained.select(:build_id))
                       .complete
                       .updated_at_before(5.minutes.ago)
      end
    end
  end
end
