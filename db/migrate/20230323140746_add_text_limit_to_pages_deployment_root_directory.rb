# frozen_string_literal: true

class AddTextLimitToPagesDeploymentRootDirectory < Gitlab::Database::Migration[2.1]
  disable_ddl_transaction!

  def up
    add_text_limit :pages_deployments, :root_directory, 255
  end

  def down
    remove_text_limit :pages_deployments, :root_directory
  end
end
