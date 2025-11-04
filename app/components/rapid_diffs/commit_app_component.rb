# frozen_string_literal: true

module RapidDiffs
  class CommitAppComponent < AppComponent
    delegate :discussions_endpoint, :user_permissions, to: :presenter

    protected

    def app_data
      {
        **super,
        user_permissions: user_permissions,
        discussions_endpoint: discussions_endpoint
      }
    end

    def prefetch_endpoints
      [*super, discussions_endpoint]
    end
  end
end
