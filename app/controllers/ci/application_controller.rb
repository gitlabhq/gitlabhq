module Ci
  class ApplicationController < ::ApplicationController
    def self.railtie_helpers_paths
      "app/helpers/ci"
    end

    private

    def authorize_access_project!
      unless can?(current_user, :read_project, project)
        return page_404
      end
    end

    def authorize_manage_builds!
      unless can?(current_user, :manage_builds, project)
        return page_404
      end
    end

    def authenticate_admin!
      return render_404 unless current_user.is_admin?
    end

    def authorize_manage_project!
      unless can?(current_user, :admin_project, project)
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
  end
end
