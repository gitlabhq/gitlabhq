class KodingController < ApplicationController
  skip_before_action :authenticate_user!, :reject_blocked!
  layout 'koding'

  def index
  end
end
