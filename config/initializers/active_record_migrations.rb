# frozen_string_literal: true

Gitlab::Database::Migrations::LockRetryMixin.patch!
Gitlab::Database::Migrations::MigrationOrderMixin.patch!
Gitlab::Database::Migrations::PgBackendPid.patch!
Gitlab::Database::Migrations::RunnerBackoff::ActiveRecordMixin.patch!
