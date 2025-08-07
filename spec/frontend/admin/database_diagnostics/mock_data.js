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
