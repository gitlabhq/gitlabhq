module EE
  module API
    module Entities
      #######################
      # Entities extensions #
      #######################
      module UserPublic
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
        end
      end

      module Project
        extend ActiveSupport::Concern

        prepended do
          expose :repository_storage, if: ->(_project, options) { options[:current_user].try(:admin?) }
          expose :approvals_before_merge, if: ->(project, _) { project.feature_available?(:merge_request_approvers) }
        end
      end

      module Group
        extend ActiveSupport::Concern

        prepended do
          expose :ldap_cn, :ldap_access
          expose :ldap_group_links,
          using: EE::API::Entities::LdapGroupLink,
          if: ->(group, options) { group.ldap_group_links.any? }
        end
      end

      module GroupDetail
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit
        end
      end

      module ProtectedRefAccess
        extend ActiveSupport::Concern

        prepended do
          expose :user_id
          expose :group_id
        end
      end

      module IssueBasic
        extend ActiveSupport::Concern

        prepended do
          expose :weight, if: ->(issue, _) { issue.supports_weight? }
        end
      end

      module MergeRequestBasic
        extend ActiveSupport::Concern

        prepended do
          expose :approvals_before_merge
          expose :squash, if: ->(mr, _) { mr.project.feature_available?(:merge_request_squash) }
        end
      end

      module Namespace
        extend ActiveSupport::Concern

        prepended do
          expose :shared_runners_minutes_limit, if: ->(_, options) { options[:current_user]&.admin? }
          expose :plan, if: ->(namespace, opts) { ::Ability.allowed?(opts[:current_user], :admin_namespace, namespace) } do |namespace, _|
            namespace.plan&.name
          end
        end
      end

      module Board
        extend ActiveSupport::Concern

        prepended do
          def scoped_issue_available?(board)
            board.parent.feature_available?(:scoped_issue_board)
          end

          # Default filtering configuration
          expose :name
          expose :group
          expose :milestone, using: ::API::Entities::Milestone, if: ->(board, _) { scoped_issue_available?(board) }
          expose :assignee, using: ::API::Entities::UserBasic, if: ->(board, _) { scoped_issue_available?(board) }
          expose :labels, using: ::API::Entities::LabelBasic, if: ->(board, _) { scoped_issue_available?(board) }
          expose :weight, if: ->(board, _) { scoped_issue_available?(board) }
        end
      end

      module ApplicationSetting
        extend ActiveSupport::Concern

        prepended do
          expose(*EE::ApplicationSettingsHelper.repository_mirror_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:repository_mirrors)
          end)
          expose(*EE::ApplicationSettingsHelper.external_authorization_service_attributes, if: ->(_instance, _options) do
            ::License.feature_available?(:external_authorization_service)
          end)
          expose :email_additional_text, if: ->(_instance, _opts) { ::License.feature_available?(:email_additional_text) }
        end
      end

      module Variable
        extend ActiveSupport::Concern

        prepended do
          expose :environment_scope, if: ->(variable, options) do
            if variable.respond_to?(:environment_scope)
              variable.project.feature_available?(:variable_environment_scope)
            end
          end
        end
      end

      ########################
      # EE-specific entities #
      ########################
      class ProjectPushRule < Grape::Entity
        expose :id, :project_id, :created_at
        expose :commit_message_regex, :branch_name_regex, :deny_delete_tag
        expose :member_check, :prevent_secrets, :author_email_regex
        expose :file_name_regex, :max_file_size
      end

      class LdapGroupLink < Grape::Entity
        expose :cn, :group_access, :provider
      end

      class RelatedIssue < ::API::Entities::Issue
        expose :issue_link_id
      end

      class Epic < Grape::Entity
        expose :id
        expose :iid
        expose :group_id
        expose :title
        expose :description
        expose :author, using: ::API::Entities::UserBasic
        expose :start_date
        expose :end_date
        expose :created_at
        expose :updated_at
        expose :labels do |epic, options|
          # Avoids an N+1 query since labels are preloaded
          epic.labels.map(&:title).sort
        end
      end

      class EpicIssue < ::API::Entities::Issue
        expose :epic_issue_id
        expose :relative_position
      end

      class EpicIssueLink < Grape::Entity
        expose :id
        expose :relative_position
        expose :epic, using: EE::API::Entities::Epic
        expose :issue, using: ::API::Entities::IssueBasic
      end

      class IssueLink < Grape::Entity
        expose :source, as: :source_issue, using: ::API::Entities::IssueBasic
        expose :target, as: :target_issue, using: ::API::Entities::IssueBasic
      end

      class Approvals < Grape::Entity
        expose :user, using: ::API::Entities::UserBasic
      end

      class MergeRequestApprovals < ::API::Entities::ProjectEntity
        expose :merge_status
        expose :approvals_required
        expose :approvals_left
        expose :approvals, as: :approved_by, using: EE::API::Entities::Approvals
        expose :approvers_left, as: :suggested_approvers, using: ::API::Entities::UserBasic

        expose :user_has_approved do |merge_request, options|
          merge_request.has_approved?(options[:current_user])
        end

        expose :user_can_approve do |merge_request, options|
          merge_request.can_approve?(options[:current_user])
        end
      end

      class LdapGroup < Grape::Entity
        expose :cn
      end

      class GitlabLicense < Grape::Entity
        expose :starts_at, :expires_at, :licensee, :add_ons

        expose :user_limit do |license, options|
          license.restricted?(:active_user_count) ? license.restrictions[:active_user_count] : 0
        end

        expose :active_users do |license, options|
          ::User.active.count
        end
      end

      class GeoNode < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers

        expose :id
        expose :url
        expose :primary?, as: :primary
        expose :enabled
        expose :current?, as: :current
        expose :files_max_capacity
        expose :repos_max_capacity

        # Retained for backwards compatibility. Remove in API v5
        expose :clone_protocol do |_record, _options|
          'http'
        end

        expose :web_edit_url do |geo_node|
          ::Gitlab::Routing.url_helpers.edit_admin_geo_node_url(geo_node)
        end

        expose :_links do
          expose :self do |geo_node|
            expose_url api_v4_geo_nodes_path(id: geo_node.id)
          end

          expose :status do |geo_node|
            expose_url api_v4_geo_nodes_status_path(id: geo_node.id)
          end

          expose :repair do |geo_node|
            expose_url api_v4_geo_nodes_repair_path(id: geo_node.id)
          end
        end
      end

      class GeoNodeStatus < Grape::Entity
        include ::API::Helpers::RelatedResourcesHelpers
        include ActionView::Helpers::NumberHelper

        expose :geo_node_id

        expose :healthy?, as: :healthy
        expose :health do |node|
          node.healthy? ? 'Healthy' : node.health
        end
        expose :health_status
        expose :missing_oauth_application

        expose :attachments_count
        expose :attachments_synced_count
        expose :attachments_failed_count
        expose :attachments_synced_missing_on_primary_count
        expose :attachments_synced_in_percentage do |node|
          number_to_percentage(node.attachments_synced_in_percentage, precision: 2)
        end

        expose :db_replication_lag_seconds

        expose :lfs_objects_count
        expose :lfs_objects_synced_count
        expose :lfs_objects_failed_count
        expose :lfs_objects_synced_missing_on_primary_count
        expose :lfs_objects_synced_in_percentage do |node|
          number_to_percentage(node.lfs_objects_synced_in_percentage, precision: 2)
        end

        expose :job_artifacts_count
        expose :job_artifacts_synced_count
        expose :job_artifacts_failed_count
        expose :job_artifacts_synced_missing_on_primary_count
        expose :job_artifacts_synced_in_percentage do |node|
          number_to_percentage(node.job_artifacts_synced_in_percentage, precision: 2)
        end

        expose :repositories_count
        expose :repositories_failed_count
        expose :repositories_synced_count
        expose :repositories_synced_in_percentage do |node|
          number_to_percentage(node.repositories_synced_in_percentage, precision: 2)
        end

        expose :wikis_count
        expose :wikis_failed_count
        expose :wikis_synced_count
        expose :wikis_synced_in_percentage do |node|
          number_to_percentage(node.wikis_synced_in_percentage, precision: 2)
        end

        expose :repository_verification_enabled

        expose :repositories_verification_failed_count
        expose :repositories_verified_count
        expose :repositories_verified_in_percentage do |node|
          number_to_percentage(node.repositories_verified_in_percentage, precision: 2)
        end

        expose :wikis_verification_failed_count
        expose :wikis_verified_count
        expose :wikis_verified_in_percentage do |node|
          number_to_percentage(node.wikis_verified_in_percentage, precision: 2)
        end

        expose :replication_slots_count
        expose :replication_slots_used_count
        expose :replication_slots_used_in_percentage do |node|
          number_to_percentage(node.replication_slots_used_in_percentage, precision: 2)
        end
        expose :replication_slots_max_retained_wal_bytes

        expose :last_event_id
        expose :last_event_timestamp
        expose :cursor_last_event_id
        expose :cursor_last_event_timestamp

        expose :last_successful_status_check_timestamp

        expose :version
        expose :revision

        expose :selective_sync_type

        # Deprecated: remove in API v5. We use selective_sync_type instead now.
        expose :namespaces, using: ::API::Entities::NamespaceBasic

        expose :updated_at

        # We load GeoNodeStatus data in two ways:
        #
        # 1. Directly by asking a Geo node via an API call
        # 2. Via cached state in the database
        #
        # We don't yet cached the state of the shard information in the database, so if
        # we don't have this information omit from the serialization entirely.
        expose :storage_shards, using: StorageShardEntity, if: ->(status, options) do
          status.storage_shards.present?
        end

        expose :storage_shards_match?, as: :storage_shards_match, if: ->(status, options) do
          ::Gitlab::Geo.primary? && status.storage_shards.present?
        end

        expose :_links do
          expose :self do |geo_node_status|
            expose_url api_v4_geo_nodes_status_path(id: geo_node_status.geo_node_id)
          end

          expose :node do |geo_node_status|
            expose_url api_v4_geo_nodes_path(id: geo_node_status.geo_node_id)
          end
        end

        private

        def namespaces
          object.geo_node.namespaces
        end

        def missing_oauth_application
          object.geo_node.missing_oauth_application?
        end
      end
    end
  end
end
