module Ci
  class PipelineSubscription < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :user
    belongs_to :pipeline, class_name: 'Ci::Pipeline'
  end
end
