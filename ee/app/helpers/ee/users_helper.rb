# frozen_string_literal: true

module EE
  module UsersHelper
    def users_sentence(users, link_class: nil)
      users.map { |user| link_to(user.name, user, class: link_class) }.to_sentence.html_safe
    end

    def user_namespace_union(user = current_user, select = :id)
      ::Gitlab::SQL::Union.new([
        ::Namespace.select(select).where(type: nil, owner: user),
        user.owned_groups.select(select).where(parent_id: nil)
      ]).to_sql
    end

    def user_has_namespace_with_trial?(user = current_user)
      ::Namespace
        .from("(#{user_namespace_union(user, :trial_ends_on)}) #{::Namespace.table_name}")
        .where('trial_ends_on > ?', Time.now.utc)
        .any?
    end

    def user_has_namespace_with_gold?(user = current_user)
      ::Namespace
        .includes(:plan)
        .where("namespaces.id IN (#{user_namespace_union(user)})") # rubocop:disable GitlabSecurity/SqlInjection
        .where.not(plans: { id: nil })
        .any?
    end
  end
end
