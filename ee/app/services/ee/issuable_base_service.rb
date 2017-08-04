module EE
  module IssuableBaseService
    private

    def filter_params(issuable)
      params.delete(:weight) unless issuable.supports_weight?

      super
    end
  end
end
