# frozen_string_literal: true

module Ci
  class DagStageEntity < Grape::Entity
    expose :name

    expose :groups, with: Ci::DagJobGroupEntity
  end
end
