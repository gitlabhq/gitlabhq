# frozen_string_literal: true

class GroupGroupLinkPolicy < ::BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:can_read_shared_with_group) { can?(:read_group, @subject.shared_with_group) }
  condition(:group_admin) { can?(:admin_group, @subject.shared_group) }

  rule { can_read_shared_with_group | group_admin }.enable :read_shared_with_group
end
