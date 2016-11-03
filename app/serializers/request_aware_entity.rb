module RequestAwareEntity
  attr_reader :request

  def initialize(object, options = {})
    super(object, options)

    @request = options.fetch(:request)
    @urls = Gitlab::Routing.url_helpers
  end
end
