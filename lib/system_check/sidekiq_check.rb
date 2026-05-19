# frozen_string_literal: true

module SystemCheck
  # Used by gitlab:sidekiq:check rake task
  class SidekiqCheck < BaseCheck
    set_name 'Sidekiq:'

    SYSTEMD_UNIT_PATH = '/run/systemd/units/invocation:gitlab-sidekiq.service'

    def multi_check
      check_sidekiq_running
      only_one_sidekiq_running
    end

    private

    def check_sidekiq_running
      print "Running? ... " # rubocop:disable Rails/Output -- system check CLI output

      if sidekiq_worker_process_count > 0
        say Rainbow("yes").green
      else
        say Rainbow("no").red
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

      print 'Number of Sidekiq processes (cluster/worker) ... ' # rubocop:disable Rails/Output -- system check CLI output

      if cluster_count == 1 && worker_count >= 1
        say Rainbow("#{cluster_count}/#{worker_count}").green
      elsif File.symlink?(SYSTEMD_UNIT_PATH)
        say Rainbow("#{cluster_count}/#{worker_count}").red
        try_fixing_it(
          'sudo systemctl restart gitlab-sidekiq.service'
        )
        fix_and_rerun
      else
        say Rainbow("#{cluster_count}/#{worker_count}").red
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
      ps_ux, _ = Gitlab::Popen.popen(%w[ps uxww])
      ps_ux.lines.grep(/sidekiq \d+\.\d+\.\d+/).count
    end

    def sidekiq_cluster_process_count
      ps_ux, _ = Gitlab::Popen.popen(%w[ps uxww])
      ps_ux.lines.grep(/sidekiq-cluster/).count
    end
  end
end
