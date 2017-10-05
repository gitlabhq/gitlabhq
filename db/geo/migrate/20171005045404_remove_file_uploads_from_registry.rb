class RemoveFileUploadsFromRegistry < ActiveRecord::Migration
  # Previous to GitLab 10.0, GitLab would save attachments/avatars to the wrong
  # directory. Destroy these entries so they will be downloaded again.
  def change
    Geo::FileRegistry.destroy_all
  end
end
