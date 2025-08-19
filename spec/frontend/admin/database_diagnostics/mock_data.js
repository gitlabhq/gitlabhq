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
          table_name: 'users',
          column_name: 'email',
          index_name: 'index_users_on_email',
        },
        {
          table_name: 'projects',
          column_name: 'name',
          index_name: 'index_projects_on_name',
        },
      ],
      missing_tables: [
        {
          table_name: 'audit_logs',
          schema: 'public',
        },
      ],
      missing_foreign_keys: [
        {
          table_name: 'merge_requests',
          column_name: 'project_id',
          referenced_table: 'projects',
        },
      ],
      missing_sequences: [
        {
          sequence_name: 'users_id_seq',
          table_name: 'users',
        },
      ],
    },
    ci: {
      missing_indexes: [
        {
          table_name: 'ci_builds',
          column_name: 'status',
          index_name: 'index_ci_builds_on_status',
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
          table_name: 'users',
          column_name: 'email',
          index_name: 'index_users_on_email',
        },
      ],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};

export const multiDatabaseResults = {
  metadata: {
    last_run_at: '2025-07-23T10:00:00Z',
  },
  schema_check_results: {
    main: {
      missing_indexes: [{ table_name: 'users', column_name: 'email' }],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
    ci: {
      missing_indexes: [{ table_name: 'ci_builds', index_name: 'ci_index' }],
      missing_tables: [],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
    registry: {
      missing_indexes: [],
      missing_tables: [{ table_name: 'registry_table' }],
      missing_foreign_keys: [],
      missing_sequences: [],
    },
  },
};

// Mock data for the more complex SchemaSection component
export const complexIssueData = {
  missing: ['missing_index_1', 'missing_index_2'],
  extra: ['extra_column_1'],
  invalid: ['invalid_constraint_1'],
  inconsistent: ['inconsistent_data_1', 'inconsistent_data_2'],
};
