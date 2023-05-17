# frozen_string_literal: true

module Gitlab
  module Database
    module AsyncConstraints
      module Validators
        MAPPING = {
          foreign_key: Validators::ForeignKey,
          check_constraint: Validators::CheckConstraint
        }.freeze

        def self.for(record)
          MAPPING
            .fetch(record.constraint_type.to_sym)
            .new(record)
        end
      end
    end
  end
end
