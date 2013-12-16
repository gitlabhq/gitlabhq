class Profiles::KeysController < ApplicationController
  layout "profile"

  def index
    @keys = current_user.keys.order('id DESC')
  end

  def show
    @key = current_user.keys.find(params[:id])
  end

  def new
    @key = current_user.keys.new
  end

  def create
    @key = current_user.keys.new(params[:key])

    if @key.save
      redirect_to profile_key_path(@key)
    else
      render 'new'
    end
  end

  def destroy
    @key = current_user.keys.find(params[:id])
    @key.destroy

    respond_to do |format|
      format.html { redirect_to profile_keys_url }
      format.js { render nothing: true }
    end
  end
end
