# frozen_string_literal: true

module Ci
  class BuildNeed < ApplicationRecord
    extend Gitlab::Ci::Model

    belongs_to :build, class_name: "Ci::Build", foreign_key: :build_id, inverse_of: :needs

    validates :build, presence: true
    validates :name, presence: true, length: { maximum: 128 }

    scope :scoped_build, -> { where('ci_builds.id=ci_build_needs.build_id') }
    scope :artifacts, -> { where(artifacts: true) }
  end
end
