module EE
  module IssuableActions
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_PERMITTED_KEYS = %w[
        weight
    ].freeze

    override :permitted_keys
    def permitted_keys
      @permitted_keys ||= (super + EE_PERMITTED_KEYS).freeze
    end
  end
end
