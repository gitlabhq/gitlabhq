# frozen_string_literal: true

module UserTypeEnums
  def self.types
    bots
  end

  def self.bots
    {
      AlertBot: 2
    }
  end
end

UserTypeEnums.prepend_if_ee('EE::UserTypeEnums')
