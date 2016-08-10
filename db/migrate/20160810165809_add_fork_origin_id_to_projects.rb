# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class AddForkOriginIdToProjects < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  include Gitlab::Database

  DOWNTIME = true

  class Project < ActiveRecord::Base
    self.table_name = 'projects'
  end

  def up
    add_column :projects, :origin_fork_id, :integer, default: nil, null: true

    transaction do
      Project.joins('INNER JOIN forked_project_links ON projects.id = forked_project_links.forked_to_project_id')
             .select('projects.id, forked_project_links.forked_from_project_id').find_in_batches do |rows|
        forked_origin_ids = {}

        rows.each do |project|
          origin_fork_id = project.forked_from_project_id
          next_fork = %Q{SELECT forked_from_project_id FROM forked_project_links WHERE forked_to_project_id = #{origin_fork_id}}

          result = select_all(next_fork)
          until result.first.nil?
            if forked_origin_ids.key?(origin_fork_id)
              origin_fork_id = forked_origin_ids[origin_fork_id]
              break
            end

            origin_fork_id = result.first["forked_from_project_id"]
            result = select_all(next_fork)
          end

          forked_origin_ids[project.id] = origin_fork_id
        end

        whens = forked_origin_ids.map do |(project_id, origin_id)|
          "WHEN id = #{project_id} THEN #{origin_id}"
        end

        Project.where(id: forked_origin_ids.keys).update_all("origin_fork_id = CASE #{whens.join(' ')} END")
      end
    end
  end

  def down
    remove_column :projects, :origin_fork_id
  end
end
