module Ci
  class ApplicationController < ::ApplicationController
    def self.railtie_helpers_paths
      "app/helpers/ci"
    end

    include Ci::UserSessionsHelper

    rescue_from Ci::Network::UnauthorizedError, with: :invalid_token
    before_filter :default_headers
    #before_filter :check_config
    helper_method :gl_project

    protect_from_forgery

    private

    def authenticate_public_page!
      unless project.public
        unless current_user
          redirect_to(new_user_sessions_path) and return
        end

        return access_denied! unless can?(current_user, :read_project, gl_project)
      end
    end

    def authenticate_token!
      unless project.valid_token?(params[:token])
        return head(403)
      end
    end

    def authorize_access_project!
      unless can?(current_user, :read_project, gl_project)
        return page_404
      end
    end

    def authorize_manage_builds!
      unless can?(current_user, :manage_builds, gl_project)
        return page_404
      end
    end

    def authenticate_admin!
      return render_404 unless current_user.is_admin?
    end

    def authorize_manage_project!
      unless can?(current_user, :manage_project, gl_project)
        return page_404
      end
    end

    def page_404
      render file: "#{Rails.root}/public/404.html", status: 404, layout: false
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

    def gl_project
      ::Project.find(@project.gitlab_id)
    end
  end
end
