module Ci
  class Stage < ActiveRecord::Base
    extend Ci::Model
    include HasStatus

    enumerated_status!

    belongs_to :project
    belongs_to :pipeline

    has_many :statuses, class_name: 'CommitStatus', foreign_key: :commit_id
    has_many :builds, foreign_key: :commit_id
  end
end
