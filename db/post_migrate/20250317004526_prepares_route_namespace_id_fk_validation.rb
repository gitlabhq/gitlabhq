# frozen_string_literal: true

class PreparesRouteNamespaceIdFkValidation < Gitlab::Database::Migration[2.2]
  milestone '17.11'

  FK_NAME = :fk_679ff8213d

  def up
    # FK to be validated synchronously in https://gitlab.com/gitlab-org/gitlab/-/issues/525273
    prepare_async_foreign_key_validation :routes, :namespace_id, name: FK_NAME
  end

  def down
    unprepare_async_foreign_key_validation :routes, :namespace_id, name: FK_NAME
  end
end
