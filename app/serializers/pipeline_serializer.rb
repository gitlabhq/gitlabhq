class PipelineSerializer < BaseSerializer
  entity PipelineEntity

  def incremental(resource, last_updated)
    represent(resource, incremental: true,
                        last_updated: last_updated)
  end
end
