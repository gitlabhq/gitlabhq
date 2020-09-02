# frozen_string_literal: true

class BaseSerializer
  attr_reader :params

  def initialize(params = {})
    @params = params
    @request = EntityRequest.new(params)
  end

  def represent(resource, opts = {}, entity_class = nil)
    entity_class ||= self.class.entity_class

    entity_class
      .represent(resource, opts.merge(request: @request))
      .as_json
  end

  class << self
    attr_reader :entity_class

    def entity(entity_class)
      @entity_class ||= entity_class
    end
  end
end
