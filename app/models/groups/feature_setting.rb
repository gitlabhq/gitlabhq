# frozen_string_literal: true

module Groups
  class FeatureSetting < ApplicationRecord
    include Featurable
    extend ::Gitlab::Utils::Override

    self.primary_key = :group_id
    self.table_name = 'group_features'

    belongs_to :group

    validates :group, presence: true

    private

    override :resource_member?
    def resource_member?(user, feature)
      group.member?(user, ::Groups::FeatureSetting.required_minimum_access_level(feature))
    end
  end
end

::Groups::FeatureSetting.prepend_mod_with('Groups::FeatureSetting')
