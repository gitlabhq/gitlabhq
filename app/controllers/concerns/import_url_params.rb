# frozen_string_literal: true

module ImportUrlParams
  include Gitlab::Utils::StrongMemoize

  def import_url_params
    return {} unless project_import_url_params&.dig(:import_url).present?

    {
      import_url: import_params_to_full_url(project_import_url_params),
      # We need to set import_type because attempting to retry an import by URL
      # could leave a stale value around. This would erroneously cause an importer
      # (e.g. import/export) to run.
      import_type: 'git'
    }
  end

  def import_params_to_full_url(params)
    Gitlab::UrlSanitizer.new(
      params[:import_url],
      credentials: {
        user: params[:import_url_user],
        password: params[:import_url_password]
      }
    ).full_url
  end

  private

  def project_import_url_params
    params.permit(project: [:import_url, :import_url_user, :import_url_password])[:project]
  end
  strong_memoize_attr :project_import_url_params
end
