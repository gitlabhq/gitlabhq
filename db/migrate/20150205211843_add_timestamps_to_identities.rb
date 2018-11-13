# rubocop:disable all
class AddTimestampsToIdentities < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:identities)
  end
end
