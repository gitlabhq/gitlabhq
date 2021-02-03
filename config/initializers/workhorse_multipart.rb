# frozen_string_literal: true

Rails.application.configure do |config|
  # ApolloUploadServer::Middleware expects to find uploaded files ready to use
  config.middleware.insert_before(ApolloUploadServer::Middleware, Gitlab::Middleware::Multipart)
end

# The Gitlab::Middleware::Multipart middleware inserts instances of our
# own ::UploadedFile class in the Rack env of requests. These instances
# will be blocked by the 'strong parameters' feature of ActionController
# unless we somehow whitelist them. At the moment it seems the only way
# to do that is by monkey-patching.
#
module Gitlab
  module StrongParameterScalars
    def permitted_scalar?(value)
      super || value.is_a?(::UploadedFile)
    end
  end
end

module ActionController
  class Parameters
    prepend Gitlab::StrongParameterScalars
  end
end
