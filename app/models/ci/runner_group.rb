module Ci
  class RunnerGroup < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :runner
    belongs_to :group, class_name: '::Group'
  end
end
