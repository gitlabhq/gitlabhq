class Admin::BackgroundJobsController < Admin::ApplicationController
  def show
    use_secure_headers_override(:background_jobs)

    ps_output, _ = Gitlab::Popen.popen(%W(ps -U #{Gitlab.config.gitlab.user} -o pid,pcpu,pmem,stat,start,command))
    @sidekiq_processes = ps_output.split("\n").grep(/sidekiq/)
  end
end
