# frozen_string_literal: true
module Ci
  class BuildEnvironmentDeployment < ActiveRecord::Base
    extend Gitlab::Ci::Model

    belongs_to :build, class_name: 'Ci::Build', foreign_key: :build_id
    belongs_to :environment
    belongs_to :deployment

    validates :environment_id, uniqueness: { scope: :build_id }
    validates :build, :environment, presence: true

    delegate :project, to: :build
  end
end
