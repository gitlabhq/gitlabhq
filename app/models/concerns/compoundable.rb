module Compoundable
  extend ActiveSupport::Concern

  class_methods do
    private

    def component(name, klass)
      define_method(name) do
        component_object = instance_variable_get("@#{name}")
        return component_object if component_object
        instance_variable_set("@#{name}", klass.new(self))
      end

      klass.instance_methods(false).each do |method|
        delegate method, to: name
      end
    end
  end
end
