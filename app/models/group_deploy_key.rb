# frozen_string_literal: true

class GroupDeployKey < Key
  self.table_name = 'group_deploy_keys'

  has_many :group_deploy_keys_groups, inverse_of: :group_deploy_key, dependent: :destroy # rubocop:disable Cop/ActiveRecordDependent
  has_many :groups, through: :group_deploy_keys_groups

  validates :user, presence: true

  scope :for_groups, ->(group_ids) do
    joins(:group_deploy_keys_groups).where(group_deploy_keys_groups: { group_id: group_ids }).uniq
  end

  # Remove usage_type because it defined in Key class but doesn't have a column in group_deploy_keys table
  def self.defined_enums
    super.without('usage_type')
  end

  # Remove Key#usage_type from attributes to avoid defining enum for it
  def self.attributes_to_define_after_schema_loads
    super.without('usage_type')
  end

  def type
    'DeployKey'
  end

  def group_deploy_keys_group_for(group)
    group_deploy_keys_groups.find_by(group: group)
  end

  def can_be_edited_for?(user, group)
    Ability.allowed?(user, :update_group_deploy_key, self) ||
      Ability.allowed?(
        user,
        :update_group_deploy_key_for_group,
        group_deploy_keys_group_for(group)
      )
  end

  def group_deploy_keys_groups_for_user(user)
    group_deploy_keys_groups.select do |group_deploy_keys_group|
      Ability.allowed?(user, :read_group, group_deploy_keys_group.group)
    end
  end
end
