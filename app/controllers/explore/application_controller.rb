class Explore::ApplicationController < ApplicationController
  before_action :set_title

  private

  def set_title
    @title      = "Explore GitLab"
    @title_url  = explore_root_path
    @sidebar    = "explore"
  end
end
