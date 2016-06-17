class Admin::BackgroundJobsController < Admin::ApplicationController
  def show
    ps_output, _ = Gitlab::Popen.popen(%W(ps -U #{Gitlab.config.gitlab.user} -o pid,pcpu,pmem,stat,start,command))
    @sidekiq_processes = ps_output.split("\n").grep(/sidekiq/)

    override_x_frame_options("SAMEORIGIN")

    override_content_security_policy_directives(frame_ancestors: %w('self'))
  end
end
