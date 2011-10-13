class Admin::UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def index
    @admin_users = User.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @admin_users }
    end
  end

  def show
    @admin_user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @admin_user }
    end
  end

  def new
    @admin_user = User.new(:projects_limit => 10)

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @admin_user }
    end
  end

  def edit
    @admin_user = User.find(params[:id])
  end

  def create
    admin = params[:user].delete("admin")

    @admin_user = User.new(params[:user]) 
    @admin_user.admin = (admin && admin.to_i > 0)

    respond_to do |format|
      if @admin_user.save
        Notify.new_user_email(@admin_user, params[:user][:password]).deliver
        format.html { redirect_to [:admin, @admin_user], notice: 'User was successfully created.' }
        format.json { render json: @admin_user, status: :created, location: @admin_user }
      else
        format.html { render action: "new" }
        format.json { render json: @admin_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    admin = params[:user].delete("admin")
    if params[:user][:password].empty?
      params[:user].delete(:password) 
      params[:user].delete(:password_confirmation) 
    end

    @admin_user = User.find(params[:id])
    @admin_user.admin = (admin && admin.to_i > 0)

    respond_to do |format|
      if @admin_user.update_attributes(params[:user])
        format.html { redirect_to [:admin, @admin_user], notice: 'User was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: @admin_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @admin_user = User.find(params[:id])
    @admin_user.destroy

    respond_to do |format|
      format.html { redirect_to admin_users_url }
      format.json { head :ok }
    end
  end
end
