# frozen_string_literal: true

class Ci::Lint::ResultEntity < Grape::Entity
  expose :valid?, as: :valid
  expose :errors
  expose :warnings
  expose :jobs, using: Ci::Lint::JobEntity do |result, options|
    next [] unless result.valid?

    result.jobs
  end
end
