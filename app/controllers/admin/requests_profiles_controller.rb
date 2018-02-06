class Admin::RequestsProfilesController < Admin::ApplicationController
  def index
    @profile_token = Gitlab::RequestProfiler.profile_token
    @profiles      = Gitlab::RequestProfiler::Profile.all.group_by(&:request_path)
  end

  def show
    clean_name = Rack::Utils.clean_path_info(params[:name])
    profile    = Gitlab::RequestProfiler::Profile.find(clean_name)

    if profile
      render text: profile.content
    else
      redirect_to admin_requests_profiles_path, alert: 'Profile not found'
    end
  end
end
