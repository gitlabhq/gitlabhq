# frozen_string_literal: true

class ConfirmSupportBotUser < ActiveRecord::Migration[6.0]
  SUPPORT_BOT_TYPE = 1

  def up
    users = Arel::Table.new(:users)
    um = Arel::UpdateManager.new
    um.table(users)
      .where(users[:user_type].eq(SUPPORT_BOT_TYPE))
      .where(users[:confirmed_at].eq(nil))
      .set([[users[:confirmed_at], Arel::Nodes::NamedFunction.new('COALESCE', [users[:created_at], Arel::Nodes::SqlLiteral.new('NOW()')])]])
    connection.execute(um.to_sql)
  end

  def down
    # no op

    # The up migration allows for the possibility that the support user might
    # have already been manually confirmed. It's not reversible as this data is
    # subsequently lost.
  end
end
