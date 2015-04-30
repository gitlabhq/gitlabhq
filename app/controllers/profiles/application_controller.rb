class Profiles::ApplicationController < ApplicationController
  before_action :set_title

  private

  def set_title
    @title      = "Profile"
    @title_url  = profile_path
    @sidebar    = "profile"
  end
end
