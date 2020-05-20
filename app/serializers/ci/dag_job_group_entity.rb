# frozen_string_literal: true

module Ci
  class DagJobGroupEntity < Grape::Entity
    expose :name
    expose :size
    expose :jobs, with: Ci::DagJobEntity
  end
end
