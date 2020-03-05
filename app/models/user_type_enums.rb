# frozen_string_literal: true

module UserTypeEnums
  def self.types
    # When adding a new key, please ensure you are not conflicting
    # with EE-only keys in app/models/user_type_enums.rb
    # or app/models/user_bot_type_enums.rb
    bots
  end

  def self.bots
    {
      AlertBot: 2
    }
  end
end

UserTypeEnums.prepend_if_ee('EE::UserTypeEnums')
