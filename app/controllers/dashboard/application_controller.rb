class Dashboard::ApplicationController < ApplicationController
  before_action :set_title

  private

  def set_title
    @title      = "Dashboard"
    @title_url  = root_path
    @sidebar    = "dashboard"
  end
end
