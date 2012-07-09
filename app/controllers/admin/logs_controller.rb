class Admin::LogsController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!
end

