# frozen_string_literal: true

class AnalyticsGenericSerializer < BaseSerializer
  def represent(resource, opts = {})
    resource.symbolize_keys!

    super(resource, opts)
  end
end
