export const collationMismatchResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  databases: {
    main: {
      collation_mismatches: [
        {
          collation_name: 'en_US.UTF-8',
          provider: 'c',
          stored_version: '2.28',
          actual_version: '2.31',
        },
        {
          collation_name: 'fr_FR.UTF-8',
          provider: 'c',
          stored_version: '2.28',
          actual_version: '2.31',
        },
      ],
      corrupted_indexes: [
        {
          index_name: 'index_users_on_name',
          table_name: 'users',
          affected_columns: 'name',
          index_type: 'btree',
          is_unique: true,
          size_bytes: 5678901,
          corruption_types: ['duplicates'],
          needs_deduplication: true,
        },
      ],
      skipped_indexes: [
        {
          index_name: 'index_merge_requests_on_target_project_id',
          table_name: 'merge_requests',
          table_size_bytes: 2147483648,
          index_size_bytes: 214748364,
          table_size_threshold: 1073741824,
          reason: 'table_size_exceeds_threshold',
        },
      ],
    },
    ci: {
      collation_mismatches: [],
      corrupted_indexes: [],
    },
  },
};

export const noIssuesResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  databases: {
    main: {
      collation_mismatches: [],
      corrupted_indexes: [],
      skipped_indexes: [],
    },
  },
};

export const schemaIssuesResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  schema_check_results: {
    main: {
      missing_indexes: [
        {
          name: 'public.index_users_on_email',
        },
        {
          name: 'public.index_projects_on_name',
        },
      ],
      missing_tables: [
        {
          name: 'public.audit_logs',
        },
      ],
      missing_foreign_keys: [
        {
          name: 'public.merge_requests_project_id',
        },
      ],
      missing_sequences: [
        {
          name: 'users_id_seq',
        },
      ],
      wrong_sequence_owners: [
        {
          name: 'public.abuse_events_id_seq',
          details: {
            current_owner: 'public.achievements.id',
            expected_owner: 'public.abuse_events.id',
          },
        },
      ],
    },
    ci: {
      missing_indexes: [
        {
          name: 'public.index_ci_builds_on_status',
        },
      ],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};

export const noSchemaIssuesResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  schema_check_results: {
    main: {
      missing_indexes: [],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};

export const singleDatabaseResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  schema_check_results: {
    main: {
      missing_indexes: [
        {
          name: 'public.index_users_on_email',
        },
      ],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};

export const vacuumActivity = [
  {
    pid: 4242,
    schema_name: 'public',
    table_name: 'ci_builds',
    phase: 'vacuuming indexes',
    heap_blks_total: 1000,
    heap_blks_scanned: 600,
    heap_blks_vacuumed: 500,
    index_vacuum_count: 2,
    max_dead_tuple_bytes: 2097152,
    dead_tuple_bytes: 2000000,
    indexes_total: 5,
    indexes_processed: 3,
    vacuum_type: 'autovacuum',
    anti_wraparound: false,
    running_time_seconds: 36000,
    delay_time: 12.5,
  },
  {
    pid: 4243,
    schema_name: 'public',
    table_name: 'merge_requests',
    phase: 'scanning heap',
    heap_blks_total: 2000,
    heap_blks_scanned: 100,
    heap_blks_vacuumed: 0,
    index_vacuum_count: 0,
    max_dead_tuple_bytes: 2097152,
    dead_tuple_bytes: 50000,
    indexes_total: 3,
    indexes_processed: 0,
    vacuum_type: 'manual',
    anti_wraparound: false,
    running_time_seconds: 300,
    delay_time: null,
  },
];

export const databaseInformationResults = {
  databases: {
    main: {
      current_user: 'gitlab',
      search_path: '"$user", public',
      schemas: [
        { name: 'public', current: true, owner: 'postgres' },
        { name: 'gitlab_partitions_dynamic', current: false, owner: 'postgres' },
        { name: 'gitlab_partitions_static', current: false, owner: 'postgres' },
      ],
      findings: [],
      vacuums: vacuumActivity,
    },
  },
};

export const databaseInformationWithFindings = {
  databases: {
    main: {
      current_user: 'gitlab',
      search_path: 'public',
      schemas: [{ name: 'public', current: true, owner: 'postgres' }],
      findings: [
        {
          severity: 'error',
          code: 'search_path_missing_public',
          message: 'The public schema is not in the search path.',
        },
        {
          severity: 'warning',
          code: 'search_path_non_default',
          message: 'The search path differs from the expected default of "$user", public.',
        },
      ],
    },
  },
};

export const databaseInformationWithErrorSlice = {
  databases: {
    main: { error: 'boom' },
  },
};

export const databaseInformationWithDatabaseError = {
  databases: {
    main: { error: 'connection refused' },
  },
};

export const multiDatabaseResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  schema_check_results: {
    main: {
      missing_indexes: [{ name: 'public.index_on_users_lower_email' }],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
    ci: {
      missing_indexes: [{ name: 'public.p_ci_builds_name_id_idx' }],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
    registry: {
      missing_indexes: [],
      missing_tables: [{ name: 'public.registry_table' }],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};
