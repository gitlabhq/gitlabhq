# frozen_string_literal: true

namespace :gitlab do
  namespace :db do
    desc "GitLab | DB | squash | squash as of a version"
    task :squash, [:version] => :environment do |_t, args|
      require 'git'
      git = ::Git.open(Dir.pwd)

      squasher = Gitlab::Database::Migrations::Squasher.new(
        `git ls-tree --name-only -r #{args[:version]} -- db/migrate db/post_migrate`
      )

      new_init_structure_sql = git.show(args[:version], 'db/structure.sql')
      # Delete relevant migrations and specs
      files_to_delete = squasher.files_to_delete.filter { |f| File.exist?(f) }
      puts "\tDeleting #{files_to_delete.length} files."
      git.remove files_to_delete
      puts "\tOverwriting init_structure.sql..."
      File.write('db/init_structure.sql', new_init_structure_sql)
      git.add('db/init_structure.sql')
      puts "\tDone!".white
    end
  end
end
