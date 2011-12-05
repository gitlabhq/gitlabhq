class ErrorsController < ApplicationController
  def githost
    render :file => File.join(Rails.root, "public", "githost_error"), :layout => false
  end
end
