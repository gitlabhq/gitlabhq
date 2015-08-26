namespace :ci do
  namespace :backup do
    
    desc "GITLAB | Create a backup of the GitLab CI database"
    task create: :environment do
      configure_cron_mode

      $progress.puts "Dumping database ... ".blue
      Ci::Backup::Database.new.dump
      $progress.puts "done".green

      $progress.puts "Dumping builds ... ".blue
      Ci::Backup::Builds.new.dump
      $progress.puts "done".green

      backup = Ci::Backup::Manager.new
      backup.pack
      backup.cleanup
      backup.remove_old
    end

    desc "GITLAB | Restore a previously created backup"
    task restore: :environment do
      configure_cron_mode

      backup = Ci::Backup::Manager.new
      backup.unpack

      $progress.puts "Restoring database ... ".blue
      Ci::Backup::Database.new.restore
      $progress.puts "done".green

      $progress.puts "Restoring builds ... ".blue
      Ci::Backup::Builds.new.restore
      $progress.puts "done".green

      backup.cleanup
    end

    def configure_cron_mode
      if ENV['CRON']
        # We need an object we can say 'puts' and 'print' to; let's use a
        # StringIO.
        require 'stringio'
        $progress = StringIO.new
      else
        $progress = $stdout
      end
    end
  end

  # Disable colors for CRON
  unless STDOUT.isatty
    module Colored
      extend self

      def colorize(string, options={})
        string
      end
    end
  end
end
