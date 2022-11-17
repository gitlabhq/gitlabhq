# frozen_string_literal: true

module Gitlab
  module Ci
    module Reports
      module Security
        class Flag
          attr_reader :type, :origin, :description

          MAP = { 'flagged-as-likely-false-positive' => :false_positive }.freeze
          DEFAULT_FLAG_TYPE = :false_positive

          def flag_type
            MAP.fetch(type, DEFAULT_FLAG_TYPE)
          end

          def initialize(type: nil, origin: nil, description: nil)
            @type = type
            @origin = origin
            @description = description
          end

          def to_h
            {
              flag_type: flag_type,
              origin: origin,
              description: description
            }.compact
          end

          def false_positive?
            flag_type == :false_positive
          end
        end
      end
    end
  end
end
