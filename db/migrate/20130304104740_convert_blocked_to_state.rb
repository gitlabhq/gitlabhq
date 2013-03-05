class ConvertBlockedToState < ActiveRecord::Migration
  def up
    User.transaction do
      User.where(blocked: true).update_all(state: :blocked)
      User.where(blocked: false).update_all(state: :active)
    end
  end

  def down
    User.transaction do
      User.where(state: :blocked).update_all(blocked: :true)
    end
  end
end
