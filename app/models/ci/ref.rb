# frozen_string_literal: true

module Ci
  class Ref < ApplicationRecord
    extend Gitlab::Ci::Model

    STATUSES = %w[success failed fixed].freeze

    belongs_to :project
    belongs_to :last_updated_by_pipeline, foreign_key: :last_updated_by_pipeline_id, class_name: 'Ci::Pipeline'
    # ActiveRecord doesn't support composite FKs for this reason we have to do the 'unscope(:where)'
    # hack.
    has_many :pipelines, ->(ref) {
      # We use .read_attribute to save 1 extra unneeded query to load the :project.
      unscope(:where)
        .where(ref: ref.ref, project_id: ref.read_attribute(:project_id), tag: ref.tag)
      # Sadly :inverse_of is not supported (yet) by Rails for composite PKs.
    }, inverse_of: :ref_status

    validates :status, inclusion: { in: STATUSES }
    validates :last_updated_by_pipeline, presence: true
  end
end
