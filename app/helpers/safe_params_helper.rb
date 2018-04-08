module SafeParamsHelper
  # Rails 5.0 requires to permit parameters if used in url helpers.
  # User this helper when generating links with `params.merge(...)`
  def safe_params
    if params.respond_to?(:permit!)
      params.except(:host, :port, :protocol).permit!
    else
      params
    end
  end
end
