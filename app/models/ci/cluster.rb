module Ci
  class Cluster < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :project
    belongs_to :owner, class_name: 'User'
    belongs_to :service

  end
end
