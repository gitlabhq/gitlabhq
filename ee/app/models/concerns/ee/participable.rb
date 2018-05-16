module EE
  module Participable
    extend ::Gitlab::Utils::Override

    override :filter_by_ability
    def filter_by_ability(participants)
      return super unless self.is_a?(Epic)

      Ability.users_that_can_read_group(participants.to_a, self.group)
    end
  end
end
