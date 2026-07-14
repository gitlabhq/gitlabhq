# frozen_string_literal: true

module API
  module Entities
    class UserProfile < User
      include Users::BioHtml
    end
  end
end
