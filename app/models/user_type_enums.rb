# frozen_string_literal: true

module UserTypeEnums
  def self.types
    @types ||= bots.merge(human: nil, ghost: 5)
  end

  def self.bots
    @bots ||= { alert_bot: 2, project_bot: 6 }.with_indifferent_access
  end
end

UserTypeEnums.prepend_if_ee('EE::UserTypeEnums')
