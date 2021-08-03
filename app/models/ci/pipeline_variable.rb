# frozen_string_literal: true

module Ci
  class PipelineVariable < Ci::ApplicationRecord
    include Ci::HasVariable

    belongs_to :pipeline

    alias_attribute :secret_value, :value

    validates :key, uniqueness: { scope: :pipeline_id }

    def hook_attrs
      { key: key, value: value }
    end
  end
end
