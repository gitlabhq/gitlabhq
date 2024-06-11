# frozen_string_literal: true

class RemoveCiRunnersDeprecatedColumns < Gitlab::Database::Migration[2.2]
  milestone '17.1'

  def change
    remove_column :ci_runners, :revision, :string
    remove_column :ci_runners, :platform, :string
    remove_column :ci_runners, :architecture, :string
    remove_column :ci_runners, :ip_address, :string
    remove_column :ci_runners, :executor_type, :smallint
    remove_column :ci_runners, :config, :jsonb, default: {}, null: false
  end
end
