# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:sidekiq:check rake task
  class SidekiqCheck < BaseCheck
    set_name 'Sidekiq:'

    def multi_check
      check_sidekiq_running
      only_one_sidekiq_running
    end

    private

    def check_sidekiq_running
      $stdout.print "Running? ... "

      if sidekiq_process_count > 0
        $stdout.puts "yes".color(:green)
      else
        $stdout.puts "no".color(:red)
        try_fixing_it(
          sudo_gitlab("RAILS_ENV=production bin/background_jobs start")
        )
        for_more_information(
          see_installation_guide_section("Install Init Script"),
          "see log/sidekiq.log for possible errors"
        )
        fix_and_rerun
      end
    end

    def only_one_sidekiq_running
      process_count = sidekiq_process_count
      return if process_count == 0

      $stdout.print 'Number of Sidekiq processes ... '

      if process_count == 1
        $stdout.puts '1'.color(:green)
      else
        $stdout.puts "#{process_count}".color(:red)
        try_fixing_it(
          'sudo service gitlab stop',
          "sudo pkill -u #{gitlab_user} -f sidekiq",
          "sleep 10 && sudo pkill -9 -u #{gitlab_user} -f sidekiq",
          'sudo service gitlab start'
        )
        fix_and_rerun
      end
    end

    def sidekiq_process_count
      ps_ux, _ = Gitlab::Popen.popen(%w(ps uxww))
      ps_ux.scan(/sidekiq \d+\.\d+\.\d+/).count
    end
  end
end
