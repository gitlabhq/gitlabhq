module Ci
  class PipelineVariable < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include HasVariable

    belongs_to :pipeline

    alias_attribute :secret_value, :value

    validates :key, uniqueness: { scope: :pipeline_id }
  end
end
