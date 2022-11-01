# frozen_string_literal: true

class AddMirrorBranchRegexToRemoteMirrors < Gitlab::Database::Migration[2.0]
  disable_ddl_transaction!

  def up
    add_column :remote_mirrors, :mirror_branch_regex, :text
    add_text_limit :remote_mirrors, :mirror_branch_regex, 255
  end

  def down
    remove_text_limit :remote_mirrors, :mirror_branch_regex
    remove_column :remote_mirrors, :mirror_branch_regex
  end
end
