module Ci
  class ApplicationController < ::ApplicationController
    def self.railtie_helpers_paths
      "app/helpers/ci"
    end

    helper_method :gl_project

    private

    def authenticate_public_page!
      unless project.public
        authenticate_user!

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
      unless can?(current_user, :admin_project, gl_project)
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

    def gl_project
      ::Project.find(@project.gitlab_id)
    end
  end
end
