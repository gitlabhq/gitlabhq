namespace :gitlab do
  namespace :shell do
    desc "GITLAB | Setup gitlab-shell"
    task :setup => :environment do
      setup
    end
  end

  def setup
    warn_user_is_not_gitlab

    puts "This will rebuild an authorized_keys file."
    puts "You will lose any data stored in /home/git/.ssh/authorized_keys."
    ask_to_continue
    puts ""

    system("echo '# Managed by gitlab-shell' > /home/git/.ssh/authorized_keys")

    Key.find_each(:batch_size => 1000) do |key|
      if Gitlab::Shell.new.add_key(key.shell_id, key.key)
        print '.'
      else
        print 'F'
      end
    end

  rescue Gitlab::TaskAbortedByUserError
    puts "Quitting...".red
    exit 1
  end
end

