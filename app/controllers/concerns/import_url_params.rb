# frozen_string_literal: true

module ImportUrlParams
  def import_url_params
    return {} unless params.dig(:project, :import_url).present?

    {
      import_url: import_params_to_full_url(params[:project]),
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
end
