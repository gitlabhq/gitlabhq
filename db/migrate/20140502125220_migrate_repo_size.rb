class MigrateRepoSize < ActiveRecord::Migration
  def up
    Project.reset_column_information
    Project.find_each(batch_size: 500) do |project|
      begin
        if project.empty_repo?
          print '-'
        else
          project.update_repository_size
          print '.'
        end
      rescue
        print 'F'
      end
    end
    puts 'Done'
  end

  def down
  end
end
