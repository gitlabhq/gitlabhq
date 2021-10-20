# frozen_string_literal: true

class ChangeHelmChannelLength < Gitlab::Database::Migration[1.0]
  disable_ddl_transaction!

  def up
    add_text_limit :packages_helm_file_metadata, :channel, 255, constraint_name: check_constraint_name(:packages_helm_file_metadata, :channel, 'max_length_v2')
    remove_text_limit :packages_helm_file_metadata, :channel, constraint_name: check_constraint_name(:packages_helm_file_metadata, :channel, 'max_length')
  end

  def down
    # no-op: Danger of failing if there are records with length(channel) > 63
  end
end
