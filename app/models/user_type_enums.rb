# frozen_string_literal: true

module UserTypeEnums
  def self.types
    bots.merge(human: nil)
  end

  def self.bots
    {
      alert_bot: 2
    }.with_indifferent_access
  end
end

UserTypeEnums.prepend_if_ee('EE::UserTypeEnums')
