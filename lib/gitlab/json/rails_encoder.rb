# frozen_string_literal: true

module Gitlab
  module Json
    class RailsEncoder < ActiveSupport::JSON::Encoding::JSONGemEncoder
      def stringify(jsonified)
        ::Gitlab::Json.dump(jsonified)
      rescue EncodingError => ex
        raise JSON::GeneratorError, ex
      end
    end
  end
end
