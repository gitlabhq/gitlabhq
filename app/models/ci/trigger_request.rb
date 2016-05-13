module Ci
  class TriggerRequest < ActiveRecord::Base
    extend Ci::Model
    
    belongs_to :trigger, class_name: 'Ci::Trigger'
    belongs_to :commit, class_name: 'Ci::Commit'
    has_many :builds, class_name: 'Ci::Build'

    serialize :variables
  end
end
