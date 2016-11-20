module Gitlab
  module Ci
    module Build
      class Credentials
        attr_accessor :type, :url, :username, :password

        def initialize(type, url, username, password)
          @type = type
          @url = url
          @username = username
          @password = password
        end
      end
    end
  end
end
