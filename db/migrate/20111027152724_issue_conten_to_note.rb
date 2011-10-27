class IssueContenToNote < ActiveRecord::Migration
  def up
    raise "Not ready"
    Issue.find_each(:batch_size => 100) do |issue|
      
    end
  end

  def down
  end
end
