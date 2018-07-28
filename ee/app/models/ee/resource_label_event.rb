module EE
  module ResourceLabelEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    EE_ISSUABLE_COLUMNS = %i(epic_id).freeze

    override :issuable
    def issuable
      epic || super
    end

    override :issuable_columns
    def issuable_columns
      EE_ISSUABLE_COLUMNS + super
    end
  end
end
