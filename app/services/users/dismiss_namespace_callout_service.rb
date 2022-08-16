# frozen_string_literal: true

module Users
  class DismissNamespaceCalloutService < DismissCalloutService
    private

    def callout
      current_user.find_or_initialize_namespace_callout(params[:feature_name], params[:namespace_id])
    end
  end
end
