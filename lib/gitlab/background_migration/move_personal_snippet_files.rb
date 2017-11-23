# frozen_string_literal: true
# rubocop:disable Metrics/LineLength
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class MovePersonalSnippetFiles
      delegate :select_all, :execute, :quote_string, to: :connection

      def perform(relative_source, relative_destination)
        @source_relative_location = relative_source
        @destination_relative_location = relative_destination

        move_personal_snippet_files
      end

      def move_personal_snippet_files
        query = "SELECT uploads.path, uploads.model_id FROM uploads "\
                "INNER JOIN snippets ON snippets.id = uploads.model_id WHERE uploader = 'PersonalFileUploader'"
        select_all(query).each do |upload|
          secret = upload['path'].split('/')[0]
          file_name = upload['path'].split('/')[1]

          move_file(upload['model_id'], secret, file_name)
          update_markdown(upload['model_id'], secret, file_name)
        end
      end

      def move_file(snippet_id, secret, file_name)
        source_dir = File.join(base_directory, @source_relative_location, snippet_id.to_s, secret)
        destination_dir = File.join(base_directory, @destination_relative_location, snippet_id.to_s, secret)

        source_file_path = File.join(source_dir, file_name)
        destination_file_path = File.join(destination_dir, file_name)

        unless File.exist?(source_file_path)
          say "Source file `#{source_file_path}` doesn't exist. Skipping."
          return
        end

        say "Moving file #{source_file_path} -> #{destination_file_path}"

        FileUtils.mkdir_p(destination_dir)
        FileUtils.move(source_file_path, destination_file_path)
      end

      def update_markdown(snippet_id, secret, file_name)
        source_markdown_path = File.join(@source_relative_location, snippet_id.to_s, secret, file_name)
        destination_markdown_path = File.join(@destination_relative_location, snippet_id.to_s, secret, file_name)

        source_markdown = "](#{source_markdown_path})"
        destination_markdown = "](#{destination_markdown_path})"
        quoted_source = quote_string(source_markdown)
        quoted_destination = quote_string(destination_markdown)

        execute("UPDATE snippets "\
                "SET description = replace(snippets.description, '#{quoted_source}', '#{quoted_destination}'), description_html = NULL "\
                "WHERE id = #{snippet_id}")

        query = "SELECT id, note FROM notes WHERE noteable_id = #{snippet_id} "\
                "AND noteable_type = 'Snippet' AND note IS NOT NULL"
        select_all(query).each do |note|
          text = note['note'].gsub(source_markdown, destination_markdown)
          quoted_text = quote_string(text)

          execute("UPDATE notes SET note = '#{quoted_text}', note_html = NULL WHERE id = #{note['id']}")
        end
      end

      def base_directory
        File.join(Rails.root, 'public')
      end

      def connection
        ActiveRecord::Base.connection
      end

      def say(message)
        Rails.logger.debug(message)
      end
    end
  end
end
