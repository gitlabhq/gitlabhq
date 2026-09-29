# frozen_string_literal: true

# This a development rake task.
return if Rails.env.production?

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | squash | squash as of a version"
    task :squash, [:version] => :environment do |_t, args|
      require 'git'
      git = ::Git.open(Dir.pwd)
      delete_batch_size = 500

      squasher = Gitlab::Database::Migrations::Squasher.new(
        `git ls-tree --name-only -r #{args[:version]} -- db/migrate db/post_migrate`
      )

      # Delete relevant migrations and specs
      files_to_delete = squasher.files_to_delete.filter { |f| File.exist?(f) }
      puts "\tDeleting #{files_to_delete.length} files."

      files_to_delete.each_slice(delete_batch_size).with_index(1) do |batch, batch_number|
        puts "\tDeleting batch #{batch_number}, #{batch.length} files."
        git.remove(batch)
      end

      # Update db/init_structure.sql
      new_init_structure_sql = git.show(args[:version], 'db/structure.sql')
      new_init_structure_sql.gsub!(/^[^\n]+schema_migrations[^;]+;\n\n/m, '')
      new_init_structure_sql.gsub!(/^[^\n]+ar_internal_metadata[^;]+;\n\n/m, '')

      puts "\tOverwriting init_structure.sql..."
      File.write('db/init_structure.sql', new_init_structure_sql)
      git.add('db/init_structure.sql')

      # Update .rubocop_todo/
      deleted_files = `git diff --diff-filter=D --staged --name-only`.split("\n")
      puts "\tUpdating .rubocop_todo/..."
      git.add(Dir['.rubocop_todo/**/*.yml'].each do |todo_file|
        new_content = File.read(todo_file).split("\n").reject do |line|
          deleted_files.any? do |path|
            line.include?("'#{path}'")
          end
        end.join("\n")
        File.write(todo_file, "#{new_content}\n")
      end)

      puts "\tDone!".white
    end
  end
end
