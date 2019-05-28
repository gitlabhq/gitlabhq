# frozen_string_literal: true

module ManualInverseAssociation
  extend ActiveSupport::Concern

  class_methods do
    def manual_inverse_association(association, inverse)
      define_method(association) do
        super().tap do |value|
          next unless value

          child_association = value.association(inverse)
          child_association.set_inverse_instance(self)
          child_association.target = self
        end
      end
    end
  end
end
