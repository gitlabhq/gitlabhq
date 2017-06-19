# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.
class MovePersonalSnippetsFiles < ActiveRecord::Migration
  include Gitlab::Database::MigrationHelpers
  disable_ddl_transaction!

  DOWNTIME = false

  def up
    return unless file_storage?

    @source_relative_location = File.join('/uploads', 'personal_snippet')
    @destination_relative_location = File.join('/uploads', 'system', 'personal_snippet')

    move_personal_snippet_files
  end

  def down
    return unless file_storage?

    @source_relative_location = File.join('/uploads', 'system', 'personal_snippet')
    @destination_relative_location = File.join('/uploads', 'personal_snippet')

    move_personal_snippet_files
  end

  def move_personal_snippet_files
    query = "SELECT uploads.path, uploads.model_id, snippets.description FROM uploads "\
             "INNER JOIN snippets ON snippets.id = uploads.model_id WHERE uploader = 'PersonalFileUploader'"
    select_all(query).each do |upload|
      secret = upload['path'].split('/').first
      file_name = upload['path'].split('/').second

      next unless move_file(upload['model_id'], secret, file_name)
      update_markdown(upload['model_id'], secret, file_name, upload['description'])
    end
  end

  def move_file(snippet_id, secret, file_name)
    source_dir = File.join(base_directory, @source_relative_location, snippet_id.to_s, secret)
    destination_dir = File.join(base_directory, @destination_relative_location, snippet_id.to_s, secret)

    source_file_path = File.join(source_dir, file_name)
    destination_file_path = File.join(destination_dir, file_name)

    unless File.exist?(source_file_path)
      say "Source file `#{source_file_path}` doesn't exists. Skipping."
      return
    end

    say "Moving file #{source_file_path} -> #{destination_file_path}"

    FileUtils.mkdir_p(destination_dir)
    FileUtils.move(source_file_path, destination_file_path)

    true
  end

  def update_markdown(snippet_id, secret, file_name, description)
    source_markdown_path = File.join(@source_relative_location, snippet_id.to_s, secret, file_name)
    destination_markdown_path = File.join(@destination_relative_location, snippet_id.to_s, secret, file_name)

    source_markdown = markdown_string(source_markdown_path, file_name)
    destination_markdown = markdown_string(destination_markdown_path, file_name)

    description = description.gsub(source_markdown, destination_markdown)
    execute("UPDATE snippets SET description = '#{description}' WHERE id = #{snippet_id}")

    query = "SELECT id, note FROM notes WHERE noteable_id = #{snippet_id}"
    select_all(query).each do |note|
      text = note['note'].gsub(source_markdown, destination_markdown)

      execute("UPDATE notes SET note = '#{text}' WHERE id = #{note['id']}")
    end
  end

  def markdown_string(path, file_name)
    parts = file_name.split('.')
    base_name = parts.first
    extension = parts.second

    file_name = image_or_video?(extension) ? base_name : file_name
    escaped_filename = file_name.gsub("]", "\\]")

    markdown = "[#{escaped_filename}](#{path})"
    markdown.prepend("!") if image_or_video?(extension) || dangerous?(extension)

    markdown
  end

  def image_or_video?(extension)
    return unless extension

    images = %w[png jpg jpeg gif bmp tiff]
    videos = %w[mp4 m4v mov webm ogv]

    images.include?(extension.downcase) || videos.include?(extension.downcase)
  end

  def dangerous?(extension)
    return unless extension

    dangerous = %w[svg]

    dangerous.include?(extension.downcase)
  end

  def base_directory
    Rails.root
  end

  def file_storage?
    CarrierWave::Uploader::Base.storage == CarrierWave::Storage::File
  end
end
