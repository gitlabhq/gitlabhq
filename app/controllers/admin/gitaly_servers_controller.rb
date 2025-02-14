# frozen_string_literal: true

class Admin::GitalyServersController < Admin::ApplicationController
  feature_category :gitaly
  authorize! :read_admin_gitaly_servers, only: [:index]

  def index
    @gitaly_servers = Gitaly::Server.all
  end
end
