module Ci
  class ApplicationController < ActionController::Base
    def self.railtie_helpers_paths
      "app/helpers/ci"
    end

    include Ci::UserSessionsHelper

    rescue_from Ci::Network::UnauthorizedError, with: :invalid_token
    before_filter :default_headers
    #before_filter :check_config

    protect_from_forgery

    helper_method :current_user
    before_filter :reset_cache

    private

    def current_user
      @current_user ||= session[:ci_current_user]
    end

    def sign_in(user)
      session[:ci_current_user] = user
    end

    def sign_out
      reset_session
    end

    def authenticate_user!
      unless current_user
        redirect_to new_ci_user_sessions_path
        return
      end
    end

    def authenticate_admin!
      unless current_user && current_user.is_admin
        redirect_to new_ci_user_sessions_path
        return
      end
    end

    def authenticate_public_page!
      unless project.public
        unless current_user
          redirect_to(new_ci_user_sessions_path(state: generate_oauth_state(request.fullpath))) and return
        end

        unless current_user.can_access_project?(project.gitlab_id)
          page_404 and return
        end
      end
    end

    def authenticate_token!
      unless project.valid_token?(params[:token])
        return head(403)
      end
    end

    def authorize_access_project!
      unless current_user.can_access_project?(@project.gitlab_id)
        return page_404
      end
    end

    def authorize_project_developer!
      unless current_user.has_developer_access?(@project.gitlab_id)
        return page_404
      end
    end

    def authorize_manage_project!
      unless current_user.can_manage_project?(@project.gitlab_id)
        return page_404
      end
    end

    def page_404
      render file: "#{Rails.root}/public/404.html", status: 404, layout: false
    end

    # Reset user cache every day for security purposes
    def reset_cache
      if current_user && current_user.sync_at < (Time.zone.now - 24.hours)
        current_user.reset_cache
      end
    end

    def default_headers
      headers['X-Frame-Options'] = 'DENY'
      headers['X-XSS-Protection'] = '1; mode=block'
    end

    # JSON for infinite scroll via Pager object
    def pager_json(partial, count)
      html = render_to_string(
        partial,
        layout: false,
        formats: [:html]
      )

      render json: {
        html: html,
        count: count
      }
    end

    def check_config
      redirect_to oauth2_ci_help_path unless valid_config?
    end

    def valid_config?
      server = GitlabCi.config.gitlab_server

      if server.blank? || server.url.blank? || server.app_id.blank? || server.app_secret.blank?
        false
      else
        true
      end
    rescue Settingslogic::MissingSetting, NoMethodError
      false
    end

    def invalid_token
      reset_session
      redirect_to ci_root_path
    end
  end
end
