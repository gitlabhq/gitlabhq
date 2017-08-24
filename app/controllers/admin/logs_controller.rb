class Admin::LogsController < Admin::ApplicationController
  def show
    @loggers = [
      Gitlab::AppLogger,
      Gitlab::GitLogger,
      Gitlab::EnvironmentLogger,
      Gitlab::SidekiqLogger,
      Gitlab::RepositoryCheckLogger
    ]
  end
end
