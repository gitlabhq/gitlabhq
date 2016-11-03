class BaseSerializer
  def initialize(parameters = {})
    @entity = self.class.entity_class
    @request = EntityRequest.new(parameters)
    @opts = { request: @request }
  end

  def set(parameters)
    @request.merge!(parameters)
    self
  end

  def represent(resource, opts = {})
    @entity.represent(resource, @opts.reverse_merge(opts))
  end

  def self.entity(entity_class)
    @entity_class ||= entity_class
  end

  def self.entity_class
    @entity_class
  end
end
