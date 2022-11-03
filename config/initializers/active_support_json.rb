# frozen_string_literal: true

module ActiveSupport
  module JSON
    module Encoding
      self.json_encoder = Gitlab::Json::RailsEncoder

      # This method is used only to test that our
      # encoder maintains compatibility with the default
      # ActiveSupport encoder. See spec/lib/gitlab/json_spec.rb
      def self.use_encoder(encoder)
        previous_encoder = json_encoder
        self.json_encoder = encoder

        result = yield

        self.json_encoder = previous_encoder

        result
      end
    end
  end
end
