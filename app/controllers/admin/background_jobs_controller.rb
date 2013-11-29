class Admin::BackgroundJobsController < Admin::ApplicationController
  def show
    @sidekiq_processes = `ps -U #{Settings.gitlab.user} -o euser,pid,pcpu,pmem,stat,start,command | grep sidekiq | grep -v grep`
  end
end
