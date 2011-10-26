class Factory
  @factories = {}

  class << self
    def add(name, klass, &block)
      @factories[name] = [klass, block]
    end

    def create(name, opts = {})
      new(name, opts).tap(&:save!)
    end

    def new(name, opts)
      factory = @factories[name]
      factory[0].new.tap do |obj|
        factory[1].call(obj)
      end.tap do |obj|
        opts.each do |k, opt|
          obj.send("#{k}=", opt)
        end
      end
    end
  end
end

def Factory(name, opts={})
  Factory.create name, opts
end

