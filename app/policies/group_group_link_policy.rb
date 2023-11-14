# frozen_string_literal: true

class GroupGroupLinkPolicy < ::BasePolicy # rubocop:disable Gitlab/NamespacedClass
  condition(:can_read_shared_with_group) { can?(:read_group, @subject.shared_with_group) }
  condition(:group_member) { @subject.shared_group.member?(@user) }

  rule { can_read_shared_with_group | group_member }.enable :read_shared_with_group
end
