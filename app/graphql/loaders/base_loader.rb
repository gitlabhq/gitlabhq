# Helper methods for all loaders
module Loaders::BaseLoader
  extend ActiveSupport::Concern

  class_methods do
    # Convert a class method into a resolver proc. The method should follow the
    # (obj, args, ctx) calling convention
    def [](sym)
      resolver = method(sym)
      raise ArgumentError.new("#{self}.#{sym} is not a resolver") unless resolver.arity == 3

      resolver
    end
  end
end
