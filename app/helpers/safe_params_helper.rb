# frozen_string_literal: true

module SafeParamsHelper
  # Rails 5.0 requires to permit `params` if they're used in url helpers.
  # Use this helper when generating links with `params.merge(...)`
  # rubocop: disable CodeReuse/ActiveRecord
  def safe_params
    if params.respond_to?(:permit!)
      params.except(:host, :port, :protocol).permit!
    else
      params
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord
end
