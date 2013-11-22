# == Attributes checkable concern
#
# Make attributes checkable for the API
#
# Used by User
#
module AttributesCheckable
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_attribute_value?(attribute_name, value)
      mock = self.new(attribute_name => value)
      if mock.valid?
        true
      else
        ! mock.errors.has_key?(attribute_name)
      end
    end
  end

end
