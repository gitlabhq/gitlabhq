class PipelineDetailsEntity < PipelineEntity
  expose :details do
    ##
    # TODO consider switching to persisted stages only in pipelines table
    # (not necessairly in the show pipeline page because of #23257.
    # Hide this behind two feature flags - enabled / disabled and only
    # gitlab-ce / everywhere.
    expose :stages, as: :stages, using: StageEntity
    expose :artifacts, using: BuildArtifactEntity
    expose :manual_actions, using: BuildActionEntity
  end
end
