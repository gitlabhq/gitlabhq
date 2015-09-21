class Explore::ApplicationController < ApplicationController
  skip_before_action :authenticate_user!, :reject_blocked

  layout 'explore'
end
