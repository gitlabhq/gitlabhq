module Ci
  class Stage < ActiveRecord::Base
    extend Ci::Model
    include Importable
    include HasStatus

    enumerate_status!

    belongs_to :project
    belongs_to :pipeline

    has_many :commit_statuses, foreign_key: :stage_id
    has_many :builds, foreign_key: :stage_id

    validates :project, presence: true, unless: :importing?
    validates :pipeline, presence: true, unless: :importing?
    validates :name, presence: true, unless: :importing?
  end
end
