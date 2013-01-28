class Admin::UsersController < Admin::ApplicationController
  before_filter :admin_user, only: [:show, :edit, :update, :destroy]

  def index
    @admin_users = User.scoped
    @admin_users = @admin_users.filter(params[:filter])
    @admin_users = @admin_users.search(params[:name]) if params[:name].present?
    @admin_users = @admin_users.alphabetically.page(params[:page])
  end

  def show
    @projects = Project.scoped
    @projects = @projects.without_user(admin_user) if admin_user.authorized_projects.present?
  end

  def team_update
    UsersProject.add_users_into_projects(
      params[:project_ids],
      [admin_user.id],
      params[:project_access]
    )

    redirect_to [:admin, admin_user], notice: 'Teams were successfully updated.'
  end


  def new
    @admin_user = User.new({ projects_limit: Gitlab.config.gitlab.default_projects_limit }, as: :admin)
  end

  def edit
    admin_user
  end

  def block
    if admin_user.block
      redirect_to :back, alert: "Successfully blocked"
    else
      redirect_to :back, alert: "Error occured. User was not blocked"
    end
  end

  def unblock
    if admin_user.update_attribute(:blocked, false)
      redirect_to :back, alert: "Successfully unblocked"
    else
      redirect_to :back, alert: "Error occured. User was not unblocked"
    end
  end

  def create
    admin = params[:user].delete("admin")

    @admin_user = User.new(params[:user], as: :admin)
    @admin_user.admin = (admin && admin.to_i > 0)

    respond_to do |format|
      if @admin_user.save
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

    if params[:user][:password].blank?
      params[:user].delete(:password)
      params[:user].delete(:password_confirmation)
    end

    admin_user.admin = (admin && admin.to_i > 0)

    respond_to do |format|
      if admin_user.update_attributes(params[:user], as: :admin)
        format.html { redirect_to [:admin, admin_user], notice: 'User was successfully updated.' }
        format.json { head :ok }
      else
        format.html { render action: "edit" }
        format.json { render json: admin_user.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if admin_user.personal_projects.count > 0
      redirect_to admin_users_path, alert: "User is a project owner and can't be removed." and return
    end
    admin_user.destroy

    respond_to do |format|
      format.html { redirect_to admin_users_path }
      format.json { head :ok }
    end
  end

  protected

  def admin_user
    @admin_user ||= User.find_by_username!(params[:id])
  end
end
