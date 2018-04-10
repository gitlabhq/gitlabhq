class Admin::GitalyServersController < Admin::ApplicationController
  def index
    @gitaly_servers = Gitaly::Server.all
  end
end
