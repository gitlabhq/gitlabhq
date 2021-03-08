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

      if sidekiq_worker_process_count > 0
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
      worker_count = sidekiq_worker_process_count
      cluster_count = sidekiq_cluster_process_count
      return if worker_count == 0

      $stdout.print 'Number of Sidekiq processes (cluster/worker) ... '

      if (cluster_count == 1 && worker_count > 0) || (cluster_count == 0 && worker_count == 1)
        $stdout.puts "#{cluster_count}/#{worker_count}".color(:green)
      else
        $stdout.puts "#{cluster_count}/#{worker_count}".color(:red)
        try_fixing_it(
          'sudo service gitlab stop',
          "sudo pkill -u #{gitlab_user} -f sidekiq",
          "sleep 10 && sudo pkill -9 -u #{gitlab_user} -f sidekiq",
          'sudo service gitlab start'
        )
        fix_and_rerun
      end
    end

    def sidekiq_worker_process_count
      ps_ux, _ = Gitlab::Popen.popen(%w(ps uxww))
      ps_ux.lines.grep(/sidekiq \d+\.\d+\.\d+/).count
    end

    def sidekiq_cluster_process_count
      ps_ux, _ = Gitlab::Popen.popen(%w(ps uxww))
      ps_ux.lines.grep(/sidekiq-cluster/).count
    end
  end
end
