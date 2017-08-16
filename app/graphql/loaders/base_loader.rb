# Helper methods for all loaders
class Loaders::BaseLoader < GraphQL::Batch::Loader
  # Convert a class method into a resolver proc. The method should follow the
  # (obj, args, ctx) calling convention
  class << self
    def [](sym)
      resolver = method(sym)
      raise ArgumentError.new("#{self}.#{sym} is not a resolver") unless resolver.arity == 3

      resolver
    end
  end

  # Fulfill all keys. Pass a block that converts each result into a key.
  # Any keys not in results will be fulfilled with nil.
  def fulfill_all(results, keys, &key_blk)
    results.each do |result|
      key = yield result
      fulfill(key, result)
    end

    keys.each { |key| fulfill(key, nil) unless fulfilled?(key) }
  end
end
