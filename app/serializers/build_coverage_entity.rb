# frozen_string_literal: true

class BuildCoverageEntity < Grape::Entity
  expose :name, :coverage
end
