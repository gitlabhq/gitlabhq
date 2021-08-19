# frozen_string_literal: true

module Ci
  class TriggerRequest < Ci::ApplicationRecord
    belongs_to :trigger
    belongs_to :pipeline, foreign_key: :commit_id
    has_many :builds

    delegate :short_token, to: :trigger, prefix: true, allow_nil: true

    # We switched to Ci::PipelineVariable from Ci::TriggerRequest.variables.
    # Ci::TriggerRequest doesn't save variables anymore.
    validates :variables, absence: true

    serialize :variables # rubocop:disable Cop/ActiveRecordSerialize

    def user_variables
      return [] unless variables

      variables.map do |key, value|
        { key: key, value: value, public: false }
      end
    end
  end
end
