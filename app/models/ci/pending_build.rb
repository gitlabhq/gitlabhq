# frozen_string_literal: true

module Ci
  class PendingBuild < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :build, class_name: 'Ci::Build'

    scope :ref_protected, -> { where(protected: true) }
    scope :queued_before, ->(time) { where(arel_table[:created_at].lt(time)) }

    def self.upsert_from_build!(build)
      entry = self.new(build: build, project: build.project, protected: build.protected?)

      entry.validate!

      self.upsert(entry.attributes.compact, returning: %w[build_id], unique_by: :build_id)
    end
  end
end
