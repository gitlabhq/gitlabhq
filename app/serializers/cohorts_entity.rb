class CohortsEntity < Grape::Entity
  expose :months_included
  expose :cohorts, using: CohortEntity
end
