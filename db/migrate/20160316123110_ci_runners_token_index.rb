# rubocop:disable all
class CiRunnersTokenIndex < ActiveRecord::Migration[4.2]
  disable_ddl_transaction!

  def change
    args = [:ci_runners, :token]

    if Gitlab::Database.postgresql?
      args << { algorithm: :concurrently }
    end

    add_index(*args)
  end
end
