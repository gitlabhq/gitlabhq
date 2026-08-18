# frozen_string_literal: true

module CurrentDataContext
  extend ActiveSupport::Concern

  # Runs alongside `set_current_organization` to start observing the data context
  # (see Gitlab::Current::DataContext) separately from the legacy `Current.organization`,
  # which conflates the request's anchor, its fallback value, and its actual data boundary.
  def set_data_context
    ::Current.data_context = Gitlab::Current::DataContext.new(
      organization: current_organization_resolver.from_request,
      user: current_user
    )
  end
end
