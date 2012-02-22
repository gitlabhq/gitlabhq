class ErrorsController < ApplicationController
  layout "error"

  def githost
    render "errors/gitolite"
  end
end
