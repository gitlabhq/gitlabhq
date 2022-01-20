# frozen_string_literal: true

class UpdateInvalidMemberStates < Gitlab::Database::Migration[1.0]
  class Member < ActiveRecord::Base
    include EachBatch

    self.table_name = 'members'

    scope :in_invalid_state, -> { where(state: 2) }
  end

  def up
    Member.in_invalid_state.each_batch do |relation|
      relation.update_all(state: 0)
    end
  end

  def down
    # no-op as we don't need to revert any changed records
  end
end
