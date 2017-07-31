module RequestHelper
  # Use this in place of params when generating links from params
  # See https://github.com/rails/rails/issues/26289
  def safe_params
    params.except(:host, :port, :protocol).permit!
  end
end
