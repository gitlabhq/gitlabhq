class Admin::UsersController < AdminController
  def index
    @admin_users = User.scoped
    @admin_users = @admin_users.filter(params[:filter])
    @admin_users = @admin_users.search(params[:name]) if params[:name].present?
    @admin_users = @admin_users.order("updated_at DESC").page(params[:page])
  end

  def show
    @admin_user = User.find(params[:id])

    @projects = if @admin_user.projects.empty?
               Project
             else
               Project.without_user(@admin_user)
             end.all
  end

  def team_update
    @admin_user = User.find(params[:id])

    UsersProject.user_bulk_import(
      @admin_user,
      params[:project_ids],
      params[:project_access]
    )

    redirect_to [:admin, @admin_user], notice: 'Teams were successfully updated.'
  end


  def new
    @admin_user = User.new({ projects_limit: Gitlab.config.default_projects_limit }, as: :admin)
  end

  def edit
    @admin_user = User.find(params[:id])
  end

  def block
    @admin_user = User.find(params[:id])

    if @admin_user.block
      redirect_to :back, alert: "Successfully blocked"
    else
      redirect_to :back, alert: "Error occured. User was not blocked"
    end
  end

  def unblock
    @admin_user = User.find(params[:id])

    if @admin_user.update_attribute(:blocked, false)
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

    @admin_user = User.find(params[:id])
    @admin_user.admin = (admin && admin.to_i > 0)

    respond_to do |format|
      if @admin_user.update_attributes(params[:user], as: :admin)
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
