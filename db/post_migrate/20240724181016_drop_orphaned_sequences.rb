# frozen_string_literal: true

# DropOrphanedSequences will remove any sequences that should have
# automatically been dropped when its associated table was
# dropped. However, due to a bug in GitLab's `sequences_owned_by`
# implementation, sequences may have erroneously been assigned ownership
# to columns in the `ci_builds` or `p_ci_builds` tables. As a result, if
# the sequences were assigned to those CI tables, they may not have been
# dropped when their assocated tables were dropped.
class DropOrphanedSequences < Gitlab::Database::Migration[2.2]
  milestone '17.3'
  disable_ddl_transaction!

  # rubocop:disable Layout/LineLength -- One-line shell is more readable
  # Generated via:
  # git show origin/16-0-stable-ee:db/structure.sql | grep "CREATE SEQUENCE" | sed -E "s/CREATE SEQUENCE (.*)/\1/g" | sort > /tmp/sequences1.txt
  # git show origin/17-2-stable-ee:db/structure.sql | grep "CREATE SEQUENCE" | sed -E "s/CREATE SEQUENCE (.*)/\1/g" | sort > /tmp/sequences2.txt
  # diff /tmp/sequences1.txt /tmp/sequences2.txt | grep "<"
  # rubocop:enable Layout/LineLength
  ORPHANED_SEQUENCES = [
    'ci_editor_ai_conversation_messages_id_seq', # Dropped in GitLab 16.8: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/139626
    'ci_partitions_id_seq', # Dropped in GtiLab 17.0: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148944
    'dast_scanner_profiles_tags_id_seq', # Dropped in GitLab 17.2: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/153443
    'external_approval_rules_protected_branches_id_seq', # Dropped in GitLab 16.11: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148853
    # Geo events dropped in GitLab 17.0: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/151938
    'geo_hashed_storage_attachments_events_id_seq',
    'geo_hashed_storage_migrated_events_id_seq',
    'geo_repositories_changed_events_id_seq',
    'geo_repository_created_events_id_seq',
    'geo_repository_deleted_events_id_seq',
    'geo_repository_renamed_events_id_seq',
    'geo_repository_updated_events_id_seq',
    'geo_reset_checksum_events_id_seq',
    # End Geo events
    'in_product_marketing_emails_id_seq', # Dropped in GitLab 16.8: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/138835
    'member_tasks_id_seq', # Dropped in GitLab 16.6: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134452
    'merge_request_diff_llm_summaries_id_seq', # Dropped in GitLab 17.0: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148133
    'product_analytics_events_experimental_id_seq', # Dropped in GitLab 16.10: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/144626
    'project_repository_states_id_seq', # Dropped in GitLab 16.10: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/145195
    'sbom_vulnerable_component_versions_id_seq', # Dropped in GitLab 16.2: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125426
    'schema_inconsistencies_id_seq', # Dropped in GitLab 16.3: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/126479
    'u2f_registrations_id_seq', # Dropped in GitLab 16.1: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/114576
    'vulnerability_advisories_id_seq', # Dropped in GitLab 16.2: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125426
    'zoekt_indexed_namespaces_id_seq' # Dropped in GitLab 16.9: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/142829
  ].freeze

  def up
    ORPHANED_SEQUENCES.each do |sequence|
      with_lock_retries do
        execute("DROP SEQUENCE IF EXISTS #{sequence}")
      end
    end
  end

  def down; end
end
