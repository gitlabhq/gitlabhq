# frozen_string_literal: true

module Clusters
  class IntegrationPresenter < Gitlab::View::Presenter::Delegated
    presents ::Clusters::Integrations::Prometheus, as: :integration

    def application_type
      integration.class.name.demodulize.underscore
    end
  end
end
