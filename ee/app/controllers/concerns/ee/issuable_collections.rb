module EE
  module IssuableCollections
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    # Update old values to the actual ones.
    override :update_cookie_value
    def update_cookie_value(value)
      if value == 'weight_asc' || value == 'weight_desc'
        sort_value_weight
      else
        super
      end
    end
  end
end
