# frozen_string_literal: true

module UserBotTypeEnums
  def self.bots
    {
      alert_bot: 2
    }
  end
end

UserBotTypeEnums.prepend_if_ee('EE::UserBotTypeEnums')
