# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateUploadPathsToSystem < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers

  DOWNTIME = false
  AFFECTED_MODELS = %w(User Project Note Namespace Appearance)

  disable_ddl_transaction!

  def up
    update_column_in_batches(:uploads, :path, replace_sql(arel_table[:path], base_directory, new_upload_dir)) do |_table, query|
      query.where(uploads_to_switch_to_new_path)
    end
  end

  def down
    update_column_in_batches(:uploads, :path, replace_sql(arel_table[:path], new_upload_dir, base_directory)) do |_table, query|
      query.where(uploads_to_switch_to_old_path)
    end
  end

  # "SELECT \"uploads\".* FROM \"uploads\" WHERE \"uploads\".\"model_type\" IN ('User', 'Project', 'Note', 'Namespace', 'Appearance') AND (\"uploads\".\"path\" ILIKE 'uploads/%' AND NOT (\"uploads\".\"path\" ILIKE 'uploads/system/%'))"
  def uploads_to_switch_to_new_path
    affected_uploads.and(starting_with_base_directory).and(starting_with_new_upload_directory.not)
  end

  # "SELECT \"uploads\".* FROM \"uploads\" WHERE \"uploads\".\"model_type\" IN ('User', 'Project', 'Note', 'Namespace', 'Appearance') AND (\"uploads\".\"path\" ILIKE 'uploads/%' AND \"uploads\".\"path\" ILIKE 'uploads/system/%')"
  def uploads_to_switch_to_old_path
    affected_uploads.and(starting_with_new_upload_directory)
  end

  def starting_with_base_directory
    arel_table[:path].matches("#{base_directory}/%")
  end

  def starting_with_new_upload_directory
    arel_table[:path].matches("#{new_upload_dir}/%")
  end

  def affected_uploads
    arel_table[:model_type].in(AFFECTED_MODELS)
  end

  def base_directory
    "uploads"
  end

  def new_upload_dir
    File.join(base_directory, "-",  "system")
  end

  def arel_table
    Arel::Table.new(:uploads)
  end
end
