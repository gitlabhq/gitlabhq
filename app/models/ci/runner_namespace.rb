module Ci
  class RunnerNamespace < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :runner
    belongs_to :namespace, class_name: '::Namespace'
    belongs_to :group, class_name: '::Group', foreign_key: :namespace_id
  end
end
