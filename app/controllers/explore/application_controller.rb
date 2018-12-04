# frozen_string_literal: true

class Explore::ApplicationController < ApplicationController
  skip_before_action :authenticate_user!

  layout 'explore'
end
