class NoteCounterCache < ActiveRecord::Migration
  def up
    add_column :issues,         :notes_count, :integer, default: 0, null: false
    add_column :merge_requests, :notes_count, :integer, default: 0, null: false

    [Issue, MergeRequest].each do |model|
      model.find_each { |m| model.reset_counters(m.id, :notes) }
    end
  end

  def down
    remove_column :issues,         :notes_count
    remove_column :merge_requests, :notes_count
  end
end
