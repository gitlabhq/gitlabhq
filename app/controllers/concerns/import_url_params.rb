# frozen_string_literal: true

module ImportUrlParams
  def import_url_params
    { import_url: import_params_to_full_url(params[:project]) }
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
