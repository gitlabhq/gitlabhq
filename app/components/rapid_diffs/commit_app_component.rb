# frozen_string_literal: true

module RapidDiffs
  class CommitAppComponent < AppComponent
    delegate :discussions_endpoint, to: :presenter

    protected

    def app_data
      {
        **super,
        discussions_endpoint: discussions_endpoint
      }
    end

    def prefetch_endpoints
      [*super, discussions_endpoint]
    end
  end
end
