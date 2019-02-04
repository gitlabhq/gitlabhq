# frozen_string_literal: true

module ValidAttribute
  extend ActiveSupport::Concern

  # Checks whether an attribute has failed validation or not
  #
  # +attribute+ The symbolised name of the attribute i.e :name
  def valid_attribute?(attribute)
    self.errors.empty? || self.errors.messages[attribute].nil?
  end
end
