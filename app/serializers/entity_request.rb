# frozen_string_literal: true

class EntityRequest
  # We use EntityRequest object to collect parameters and variables
  # from the controller. Because options that are being passed to the entity
  # do appear in each entity object  in the chain, we need a way to pass data
  # that is present in the controller (see  #20045).
  #
  def initialize(parameters)
    parameters.each do |key, value|
      define_singleton_method(key) { value }
    end
  end
end
