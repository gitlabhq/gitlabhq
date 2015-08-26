class UpdateCommittedAtWithCreatedAt < ActiveRecord::Migration
  def up
    execute('UPDATE commits SET committed_at=created_at WHERE committed_at IS NULL')
  end
end
