# frozen_string_literal: true

module UserBotTypeEnums
  def self.bots
    # When adding a new key, please ensure you are not conflicting with EE-only keys in app/models/user_bot_types_enums.rb
    {
      alert_bot: 2
    }
  end
end

UserBotTypeEnums.prepend_if_ee('EE::UserBotTypeEnums')
