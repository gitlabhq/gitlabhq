# frozen_string_literal: true

if ActiveRecord.version >= Gem::Version.new("7.3")
  raise "This patch is only needed in Rails 7.1.x.x and 7.2.x.x for https://github.com/rails/rails/issues/51780"
end

# rubocop:disable Style/MissingRespondToMissing -- This is copied directly from Rails.
module ActiveRecord
  module AttributeMethods
    private

    def method_missing(name, ...)
      # We can't know whether some method was defined or not because
      # multiple thread might be concurrently be in this code path.
      # So the first one would define the methods and the others would
      # appear to already have them.
      self.class.define_attribute_methods

      # So in all cases we must behave as if the method was just defined.
      method = begin
        self.class.public_instance_method(name)
      rescue NameError
        nil
      end

      # The method might be explicitly defined in the model, but call a generated
      # method with super. So we must resume the call chain at the right step.
      method = method.super_method while method && !method.owner.is_a?(GeneratedAttributeMethods)
      if method
        method.bind_call(self, ...)
      else
        super
      end
    end
  end
end
# rubocop:enable Style/MissingRespondToMissing
