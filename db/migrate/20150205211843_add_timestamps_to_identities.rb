# rubocop:disable all
class AddTimestampsToIdentities < ActiveRecord::Migration
  def change
    add_timestamps(:identities)
  end
end
