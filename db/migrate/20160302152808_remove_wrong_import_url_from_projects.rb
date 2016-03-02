class RemoveWrongImportUrlFromProjects < ActiveRecord::Migration
  def up
    projects_with_wrong_import_url.each do |project|
      project.update_columns(import_url: nil) # TODO Check really nil?
      # TODO: migrate current credentials to import_credentials?
      # TODO: Notify user ?
    end
  end

  private


  def projects_with_dot_atom
    # TODO Check live with #operations for possible false positives. Also, consider regex? But may have issues MySQL/PSQL
    select_all("SELECT p.id from projects p WHERE p.import_url LIKE '%//%:%@%' or p.import_url like '#{"_"*40}@github.com%'")
  end
end
