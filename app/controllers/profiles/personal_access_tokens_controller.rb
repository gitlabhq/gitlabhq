class Profiles::PersonalAccessTokensController < Profiles::ApplicationController
  before_action :finder

  def index
    set_index_vars
  end

  def create
    @personal_access_token = finder.execute.build(personal_access_token_params)

    if @personal_access_token.save
      flash[:personal_access_token] = @personal_access_token.token
      redirect_to profile_personal_access_tokens_path, notice: "Your new personal access token has been created."
    else
      set_index_vars
      render :index
    end
  end

  def revoke
    @personal_access_token = finder.execute(id: params[:id])

    if @personal_access_token.revoke!
      flash[:notice] = "Revoked personal access token #{@personal_access_token.name}!"
    else
      flash[:alert] = "Could not revoke personal access token #{@personal_access_token.name}."
    end

    redirect_to profile_personal_access_tokens_path
  end

  private

  def finder
    @finder ||= PersonalAccessTokensFinder.new(user: current_user, impersonation: false)
  end

  def personal_access_token_params
    params.require(:personal_access_token).permit(:name, :expires_at, scopes: [])
  end

  def set_index_vars
    finder.params[:state] = 'active'
    @personal_access_token ||= finder.execute.build
    @scopes = Gitlab::Auth::SCOPES
    finder.params[:order] = :expires_at
    @active_personal_access_tokens = finder.execute
    finder.params[:state] = 'inactive'
    @inactive_personal_access_tokens = finder.execute
  end
end
