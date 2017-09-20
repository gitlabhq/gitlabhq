module Ci
  class PipelineVariable < ApplicationRecord
    extend Gitlab::Ci::Model
    include HasVariable

    belongs_to :pipeline

    validates :key, uniqueness: { scope: :pipeline_id }
  end
end
