class CiRunnersTokenIndex < ActiveRecord::Migration
  disable_ddl_transaction!

  def change
    args = [:ci_runners, :token]

    if Gitlab::Database.postgresql?
      args << { algorithm: :concurrently }
    end

    add_index(*args)
  end
end
