# frozen_string_literal: true

module API
  module Entities
    # Use with care, this exposes the secret
    class ApplicationWithSecret < Entities::Application
      expose :secret
    end
  end
end
