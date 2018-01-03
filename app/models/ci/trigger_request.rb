module Ci
  class TriggerRequest < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :trigger
    belongs_to :pipeline, foreign_key: :commit_id
    has_many :builds

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
