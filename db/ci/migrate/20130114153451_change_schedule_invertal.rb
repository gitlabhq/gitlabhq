class ChangeScheduleInvertal < ActiveRecord::Migration
  def up
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      connection.execute(%q{
        ALTER TABLE projects
        ALTER COLUMN polling_interval
        TYPE integer USING CAST(polling_interval AS integer)
      })
    else
      change_column :projects, :polling_interval, :integer, null: true
    end
  end

  def down
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      connection.execute(%q{
        ALTER TABLE projects
        ALTER COLUMN polling_interval
        TYPE integer USING CAST(polling_interval AS varchar)
      })
    else
      change_column :projects, :polling_interval, :string, null: true
    end
  end
end
