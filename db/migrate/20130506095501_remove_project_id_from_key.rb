class RemoveProjectIdFromKey < ActiveRecord::Migration
  def up
    puts 'Migrate deploy keys: '
    Key.where('project_id IS NOT NULL').update_all(type: 'DeployKey')

    DeployKey.all.each do |key|
      project = Project.find_by(id: key.project_id)
      if project
        project.deploy_keys << key
        print '.'
      end
    end

    puts 'Done'

    remove_column :keys, :project_id
  end

  def down
    add_column :keys, :project_id, :integer
  end
end
