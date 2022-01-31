# frozen_string_literal: true

class Admin::RequestsProfilesController < Admin::ApplicationController
  feature_category :not_owned

  def index
    @profile_token = Gitlab::RequestProfiler.profile_token
    @profiles      = Gitlab::RequestProfiler.all.group_by(&:request_path)
  end

  def show
    clean_name = Rack::Utils.clean_path_info(params[:name])
    profile    = Gitlab::RequestProfiler.find(clean_name)

    unless profile && profile.content_type
      return redirect_to admin_requests_profiles_path, alert: 'Profile not found'
    end

    send_file profile.file_path, type: "#{profile.content_type}; charset=utf-8", disposition: 'inline'
  end
end
