class Users::ContributionsController < UsersController

	@user_projects = @user.authorized_projects.accessible_to(@user)
    @repositories = @user_projects.map(&:repository)
    
end