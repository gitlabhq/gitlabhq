Rails.application.configure do |config|
  config.middleware.use(Gitlab::Middleware::Multipart)
end

# The Gitlab::Middleware::Multipart middleware inserts instances of our
# own ::UploadedFile class in the Rack env of requests. These instances
# will be blocked by the 'strong parameters' feature of ActionController
# unless we somehow whitelist them. At the moment it seems the only way
# to do that is by monkey-patching.
#
module Gitlab
  module StrongParameterScalars
    GITLAB_PERMITTED_SCALAR_TYPES = [::UploadedFile].freeze

    def permitted_scalar?(value)
      super || GITLAB_PERMITTED_SCALAR_TYPES.any? { |type| value.is_a?(type) }
    end
  end
end

module ActionController
  class Parameters
    prepend Gitlab::StrongParameterScalars
  end
end
