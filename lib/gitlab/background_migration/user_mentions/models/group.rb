# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    module UserMentions
      module Models
        # isolated Group model
        class Group < ::Gitlab::BackgroundMigration::UserMentions::Models::Namespace
          self.store_full_sti_class = false
          self.inheritance_column = :_type_disabled

          has_one :saml_provider

          def self.declarative_policy_class
            "GroupPolicy"
          end

          def max_member_access_for_user(user)
            return GroupMember::NO_ACCESS unless user

            return GroupMember::OWNER if user.admin?

            max_member_access = members_with_parents.where(user_id: user)
                                  .reorder(access_level: :desc)
                                  .first
                                  &.access_level

            max_member_access || GroupMember::NO_ACCESS
          end

          def members_with_parents
            # Avoids an unnecessary SELECT when the group has no parents
            source_ids =
              if has_parent?
                self_and_ancestors.reorder(nil).select(:id)
              else
                id
              end

            group_hierarchy_members = GroupMember.active_without_invites_and_requests
                                        .where(source_id: source_ids)

            GroupMember.from_union([group_hierarchy_members,
                                    members_from_self_and_ancestor_group_shares])
          end

          # rubocop: disable Metrics/AbcSize
          def members_from_self_and_ancestor_group_shares
            group_group_link_table = GroupGroupLink.arel_table
            group_member_table = GroupMember.arel_table

            source_ids =
              if has_parent?
                self_and_ancestors.reorder(nil).select(:id)
              else
                id
              end

            group_group_links_query = GroupGroupLink.where(shared_group_id: source_ids)
            cte = Gitlab::SQL::CTE.new(:group_group_links_cte, group_group_links_query)
            cte_alias = cte.table.alias(GroupGroupLink.table_name)

            # Instead of members.access_level, we need to maximize that access_level at
            # the respective group_group_links.group_access.
            member_columns = GroupMember.attribute_names.map do |column_name|
              if column_name == 'access_level'
                smallest_value_arel([cte_alias[:group_access], group_member_table[:access_level]],
                                    'access_level')
              else
                group_member_table[column_name]
              end
            end

            GroupMember
              .with(cte.to_arel)
              .select(*member_columns)
              .from([group_member_table, cte.alias_to(group_group_link_table)])
              .where(group_member_table[:requested_at].eq(nil))
              .where(group_member_table[:source_id].eq(group_group_link_table[:shared_with_group_id]))
              .where(group_member_table[:source_type].eq('Namespace'))
          end
          # rubocop: enable Metrics/AbcSize

          def smallest_value_arel(args, column_alias)
            Arel::Nodes::As.new(
              Arel::Nodes::NamedFunction.new('LEAST', args),
              Arel::Nodes::SqlLiteral.new(column_alias))
          end
        end
      end
    end
  end
end
