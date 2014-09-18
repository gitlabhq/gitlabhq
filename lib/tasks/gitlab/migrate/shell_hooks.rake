namespace :gitlab do
  namespace :migrate do
    task shell_hooks: :environment do
      migration_file = Rails.root.join('db/migrate/20140903115954_migrate_to_new_shell.rb')
      migration_source_file = "#{migration_file}.skip"

      unless File.exists?(migration_file)
        begin
          FileUtils.cp(migration_source_file, migration_file)
        rescue => ex
          warn "Please make sure #{migration_file} exists."
          warn "\n  sudo cp #{migration_source_file} #{migration_file}\n\n"
          raise ex
        end
      end

      gitlab_shell_path = Gitlab.config.gitlab_shell.path
      unless system("#{gitlab_shell_path}/bin/create-hooks")
        abort 'Failed to rewrite gitlab-shell hooks in repositories'
      end

      hooks_migration_id = '20140903115954'
      unless system(*%W(rake db:migrate:up VERSION=#{hooks_migration_id}))
        abort "Failed to run migration #{hooks_migration_id}"
      end

      puts 'Repositories updated with new hooks'
      begin
        FileUtils.rm(migration_file)
      rescue
        warn "Please remove #{migration_file}"
        warn "\n  sudo rm #{migration_file}\n\n"
      end
    end
  end
end
