# This class is used as a proxy for all outbounding http connection
# coming from callbacks, services and hooks. The direct use of the HTTParty
# is discouraged because it can lead to several security problems, like SSRF
# calling internal IP or services.
module Gitlab
  class HTTP
    include HTTParty # rubocop:disable Gitlab/HTTParty

    connection_adapter ProxyHTTPConnectionAdapter
  end
end
