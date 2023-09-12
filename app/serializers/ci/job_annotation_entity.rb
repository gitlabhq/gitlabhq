# frozen_string_literal: true

module Ci
  class JobAnnotationEntity < Grape::Entity
    expose :name
    expose :data
  end
end
