# frozen_string_literal: true

module Harbor
  module Access
    extend ActiveSupport::Concern

    included do
      before_action :authorize_read_harbor_registry!

      feature_category :integrations
    end

    private

    def authorize_read_harbor_registry!
      raise NotImplementedError
    end
  end
end
