# frozen_string_literal: true

class GroupGroupLink < ApplicationRecord
  include Expirable

  belongs_to :shared_group, class_name: 'Group', foreign_key: :shared_group_id
  belongs_to :shared_with_group, class_name: 'Group', foreign_key: :shared_with_group_id

  validates :shared_group, presence: true
  validates :shared_group_id, uniqueness: { scope: [:shared_with_group_id],
                                            message: N_('The group has already been shared with this group') }
  validates :shared_with_group, presence: true
  validates :group_access, inclusion: { in: Gitlab::Access.all_values }, presence: true

  scope :guests, -> { where(group_access: Gitlab::Access::GUEST) }
  scope :non_guests, -> { where('group_group_links.group_access > ?', Gitlab::Access::GUEST) }
  scope :for_shared_groups, ->(group_ids) { where(shared_group_id: group_ids) }
  scope :for_shared_with_groups, ->(group_ids) { where(shared_with_group_id: group_ids) }

  scope :with_owner_or_maintainer_access, -> do
    where(group_access: [Gitlab::Access::OWNER, Gitlab::Access::MAINTAINER])
  end

  scope :with_developer_maintainer_owner_access, -> do
    where(group_access: [Gitlab::Access::DEVELOPER, Gitlab::Access::MAINTAINER, Gitlab::Access::OWNER])
  end

  scope :with_developer_access, -> do
    where(group_access: [Gitlab::Access::DEVELOPER])
  end

  scope :with_owner_access, -> do
    where(group_access: [Gitlab::Access::OWNER])
  end

  scope :groups_accessible_via, ->(shared_with_group_ids) do
    links = where(shared_with_group_id: shared_with_group_ids)
    # a group share also gives you access to the descendants of the group being shared,
    # so we must include the descendants as well in the result.
    Group.id_in(links.select(:shared_group_id)).self_and_descendants
  end

  scope :groups_having_access_to, ->(shared_group_ids) do
    links = where(shared_group_id: shared_group_ids)
    Group.id_in(links.select(:shared_with_group_id))
  end

  scope :preload_shared_with_groups, -> { preload(:shared_with_group) }

  scope :distinct_on_shared_with_group_id_with_group_access, -> do
    distinct_group_links = select('DISTINCT ON (shared_with_group_id) *')
    .order('shared_with_group_id, group_access DESC, expires_at DESC, created_at ASC')

    unscoped.from(distinct_group_links, :group_group_links)
  end

  scope :with_at_least_group_access, ->(group_access) { where(group_access: group_access..) }

  alias_method :shared_from, :shared_group

  def self.search(query, **options)
    joins(:shared_with_group).merge(Group.search(query, **options))
  end

  def self.access_options
    Gitlab::Access.options_with_owner
  end

  def self.default_access
    Gitlab::Access::DEVELOPER
  end

  def human_access
    Gitlab::Access.human_access(self.group_access)
  end
end

GroupGroupLink.prepend_mod_with('GroupGroupLink')
