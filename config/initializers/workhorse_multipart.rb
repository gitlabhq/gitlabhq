Rails.application.configure do |config|
  config.middleware.use(Gitlab::Middleware::Multipart)
end

module Gitlab
  module StrongParameterScalars
    GITLAB_PERMITTED_SCALAR_TYPES = [::UploadedFile]

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
