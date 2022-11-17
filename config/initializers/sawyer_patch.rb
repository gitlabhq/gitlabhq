# frozen_string_literal: true
#
# This patch updates SawyerResource class to not allow Ruby methods to be overridden and accessed.
# Any attempt to access a Ruby method will result in an exception.
module SawyerClassPatch
  def attr_accessor(*attrs)
    attrs.each do |attribute|
      class_eval do
        define_method attribute do
          raise Sawyer::Error,
            "Sawyer method \"#{attribute}\" access is forbidden. Convert to a hash to access the attribute."
        end

        define_method "#{attribute}=" do |value|
          raise Sawyer::Error,
            "Sawyer method \"#{attribute}=\" access is forbidden. Convert to a hash to access the attribute."
        end

        define_method "#{attribute}?" do
          raise Sawyer::Error,
            "Sawyer method \"#{attribute}?\" overlaps Ruby method. Convert to a hash to access the attribute."
        end
      end
    end
  end
end

Sawyer::Resource.singleton_class.prepend(SawyerClassPatch)
