class EmojisController < ApplicationController
  def index
    render :index, layout: false
  end
end
