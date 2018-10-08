# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class DirectlyAddressedUserParser < UserParser
      self.reference_type = :user
      self.reference_options = { location: :beginning }
    end
  end
end
