# frozen_string_literal: true

class ValidateTimelogsNamespaceIdForeignKey < Gitlab::Database::Migration[2.3]
  FK_NAME = 'fk_d774bdf1ae'

  milestone '18.6'

  def up
    # We had to no-op this migration because the timestamp had the wrong value and we need this one to
    # be executed after 20251020103600
    # https://gitlab.com/gitlab-org/gitlab/-/issues/581680
    # no-op
  end

  def down
    # no-op
  end
end
