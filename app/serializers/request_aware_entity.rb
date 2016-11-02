module RequestAwareEntity
  def request
    options[:request] ||
      raise(StandardError, 'Request not set!!')
  end
end
