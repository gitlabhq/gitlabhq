# frozen_string_literal: true

module SignInDashboardUxSli
  private

  def start_time_for_sign_in_dashboard_ux_sli
    @start_time_of_sign_in_dashboard_ux_sli = Time.current # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This is only used within this module.
  end

  def store_start_time_for_sign_in_dashboard_ux_sli(redirect_path_or_url)
    return unless [root_path, root_url].include?(redirect_path_or_url)

    session[:start_time_of_sign_in_dashboard_ux_sli] = @start_time_of_sign_in_dashboard_ux_sli # rubocop:disable Gitlab/ModuleWithInstanceVariables -- This is only used within this module.
  end

  def observe_sign_in_dashboard_ux_sli
    start_time_of_sign_in_dashboard_ux_sli = session.delete(:start_time_of_sign_in_dashboard_ux_sli)

    return unless start_time_of_sign_in_dashboard_ux_sli
    return if start_time_of_sign_in_dashboard_ux_sli.before?(60.seconds.ago)

    Labkit::UserExperienceSli.observed(:sign_in_dashboard, start_time: start_time_of_sign_in_dashboard_ux_sli)
  end
end
