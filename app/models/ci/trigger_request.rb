module Ci
  class TriggerRequest < ActiveRecord::Base
    extend Ci::Model

    belongs_to :trigger, class_name: 'Ci::Trigger'
    belongs_to :pipeline, class_name: 'Ci::Pipeline', foreign_key: :commit_id
    has_many :builds, class_name: 'Ci::Build'

    serialize :variables
  end
end
