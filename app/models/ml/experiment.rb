# frozen_string_literal: true

module Ml
  class Experiment < ApplicationRecord
    validates :name, :iid, :project, presence: true
    validates :iid, :name, uniqueness: { scope: :project, message: "should be unique in the project" }

    belongs_to :project
    belongs_to :user
    has_many :candidates, class_name: 'Ml::Candidate'
  end
end
