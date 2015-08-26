class MoveJobNameToBuild < ActiveRecord::Migration
  def up
    select_all("SELECT id, name FROM jobs").each do |job|
      execute("UPDATE builds SET name = '#{quote_string(job["name"])}' WHERE job_id = #{job["id"]}")
    end
  end

  def down
  end
end
