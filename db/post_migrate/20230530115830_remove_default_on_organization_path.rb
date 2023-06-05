# frozen_string_literal: true

class RemoveDefaultOnOrganizationPath < Gitlab::Database::Migration[2.1]
  def up
    change_column_default :organizations, :path, nil
  end

  def down
    change_column_default :organizations, :path, ''
  end
end
