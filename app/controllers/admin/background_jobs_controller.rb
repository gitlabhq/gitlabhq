class Admin::BackgroundJobsController < Admin::ApplicationController
  def show
    ps_output, _ = Gitlab::Popen.popen(%W(ps ww -U #{Gitlab.config.gitlab.user} -o pid,pcpu,pmem,stat,start,command))
    @sidekiq_processes = ps_output.split("\n").grep(/sidekiq \d+\.\d+\.\d+/)
    @concurrency = Sidekiq.options[:concurrency]
  end
end
