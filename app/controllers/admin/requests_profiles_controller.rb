# frozen_string_literal: true

class Admin::RequestsProfilesController < Admin::ApplicationController
  def index
    @profile_token = Gitlab::RequestProfiler.profile_token
    @profiles      = Gitlab::RequestProfiler::Profile.all.group_by(&:request_path)
  end

  def show
    clean_name = Rack::Utils.clean_path_info(params[:name])
    profile    = Gitlab::RequestProfiler::Profile.find(clean_name)

    unless profile && profile.content_type
      return redirect_to admin_requests_profiles_path, alert: 'Profile not found'
    end

    send_file profile.file_path, type: "#{profile.content_type}; charset=utf-8", disposition: 'inline'
  end
end
