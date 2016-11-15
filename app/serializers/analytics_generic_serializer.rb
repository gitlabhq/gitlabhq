class AnalyticsGenericSerializer < BaseSerializer
  entity AnalyticsGenericEntity

  def represent(resource, opts = {})
    resource.symbolize_keys!

    super(resource, opts)
  end
end
