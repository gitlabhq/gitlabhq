module EE
  module BaseCountService
    # geo secondary cache should expire quicker than primary, otherwise various counts
    # could be incorrect for 2 weeks.
    def cache_options
      raise NotImplementedError.new unless defined?(super)

      value = super
      value[:expires_in] = 20.minutes if ::Gitlab::Geo.secondary?
      value
    end
  end
end
