class ErrorsController < ApplicationController
  def gitosis
    render :file => File.join(Rails.root, "public", "gitosis_error"), :layout => false
  end
end
