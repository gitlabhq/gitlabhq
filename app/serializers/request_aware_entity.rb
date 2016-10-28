module RequestAwareEntity
  # We use SerializableRequest class to collect parameters and variables
  # from the controller. Because options that are being passed to the entity
  # are appear in each entity in the chain, we need a way to access data
  # that is present in the controller (see  #20045).
  #
  def request
    options[:request] ||
      raise(StandardError, 'Request not set!!')
  end
end
