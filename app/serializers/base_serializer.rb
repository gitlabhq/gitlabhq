class BaseSerializer
  def initialize(request = {})
    @request = EntityRequest.new(request)
    @opts = { request: @request }
  end

  def set(opts)
    @request.merge!(opts)
    self
  end

  def represent(resource, opts = {})
    self.class.entity_class
      .represent(resource, @opts.reverse_merge(opts))
  end

  def self.entity(entity_class)
    @entity_class ||= entity_class
  end

  def self.entity_class
    @entity_class
  end
end
