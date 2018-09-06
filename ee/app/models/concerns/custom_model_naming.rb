module CustomModelNaming
  # Extracted from: https://github.com/stevenbarragan/spree_random_subscriptions/blob/5426ccaf8a2084c495b2cac9dfbd27e30ade0cec/lib/custom_model_naming.rb

  extend ActiveSupport::Concern

  included do
    self.class_attribute :singular_route_key, :route_key, :param_key
  end

  class_methods do
    def model_name
      @_model_name ||= begin
        namespace = self.parents.detect do |n|
          n.respond_to?(:use_relative_model_naming?) && n.use_relative_model_naming?
        end
        Name.new(self, namespace)
      end
    end
  end

  class Name < ::ActiveModel::Name
    def param_key
      @klass.param_key || super
    end

    def singular_route_key
      @klass.singular_route_key || (@klass.route_key && ActiveSupport::Inflector.singularize(@klass.route_key)) || super
    end

    def route_key
      @klass.route_key || super
    end
  end
end
