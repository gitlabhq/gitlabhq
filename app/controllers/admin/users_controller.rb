class Admin::UsersController < Admin::ApplicationController
  before_filter :user, only: [:show, :edit, :update, :destroy]

  def index
    @users = User.filter(params[:filter])
    @users = @users.search(params[:name]) if params[:name].present?
    @users = @users.alphabetically.page(params[:page])
  end

  def show
    @personal_projects = user.personal_projects
    @joined_projects = user.projects.joined(@user)
  end

  def new
    @user = User.build_user
  end

  def edit
    user
  end

  def block
    if user.block
      redirect_to :back, alert: "Successfully blocked"
    else
      redirect_to :back, alert: "Error occurred. User was not blocked"
    end
  end

  def unblock
    if user.activate
      redirect_to :back, alert: "Successfully unblocked"
    else
      redirect_to :back, alert: "Error occurred. User was not unblocked"
    end
  end

  def create
    admin = user_params.delete("admin")

    opts = {
      force_random_password: true,
      password_expires_at: Time.now
    }

    @user = User.build_user(user_params.merge(opts), as: :admin)
    @user.admin = (admin && admin.to_i > 0)
    @user.created_by_id = current_user.id
    @user.generate_password
    @user.skip_confirmation!

    respond_to do |format|
      if @user.save
        format.html { redirect_to [:admin, @user], notice: 'User was successfully created.' }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render "new" }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    admin = user_params.delete("admin")

    if user_params[:password].blank?
      user_params.delete(:password)
      user_params.delete(:password_confirmation)
    end

    if admin.present?
      user.admin = !admin.to_i.zero?
    end

    respond_to do |format|
      if user.update_attributes(user_params, as: :admin)
        user.confirm!
        format.html { redirect_to [:admin, user], notice: 'User was successfully updated.' }
        format.json { head :ok }
      else
        # restore username to keep form action url.
        user.username = params[:id]
        format.html { render "edit" }
        format.json { render json: user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    # 1. Remove groups where user is the only owner
    user.solo_owned_groups.map(&:destroy)

    # 2. Remove user with all authored content including personal projects
    user.destroy

    respond_to do |format|
      format.html { redirect_to admin_users_path }
      format.json { head :ok }
    end
  end

  def remove_email
    email = user.emails.find(params[:email_id])
    email.destroy

    respond_to do |format|
      format.html { redirect_to :back, notice: "Successfully removed email." }
      format.js { render nothing: true }
    end
  end

  protected

  def user
    @user ||= User.find_by!(username: params[:id])
  end

  def user_params
    params.require(:user).permit(
      :email, :password, :password_confirmation, :remember_me, :bio, :name, :username,
      :skype, :linkedin, :twitter, :website_url, :color_scheme_id, :theme_id, :force_random_password,
      :extern_uid, :provider, :password_expires_at, :avatar, :hide_no_ssh_key,
      :projects_limit, :can_create_group,
    )
  end
end
