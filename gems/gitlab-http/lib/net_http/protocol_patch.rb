# frozen_string_literal: true

# Monkey patch Net::HTTP to fix missing URL decoding for username and password in proxy settings
#
# See proposed upstream fix https://github.com/ruby/net-http/pull/5
# See Ruby-lang issue https://bugs.ruby-lang.org/issues/17542
# See issue on GitLab https://gitlab.com/gitlab-org/gitlab/-/issues/289836

require 'net/http'

# This file can be removed once Ruby 3.0 is no longer supported:
# https://gitlab.com/gitlab-org/gitlab/-/issues/396223
return if Gem::Version.new(Net::HTTP::VERSION) >= Gem::Version.new('0.2.0')

module Net
  class HTTP < Protocol
    def proxy_user
      if environment_variable_is_multiuser_safe? && @proxy_from_env
        user = proxy_uri&.user
        CGI.unescape(user) unless user.nil?
      else
        @proxy_user
      end
    end

    def proxy_pass
      if environment_variable_is_multiuser_safe? && @proxy_from_env
        pass = proxy_uri&.password
        CGI.unescape(pass) unless pass.nil?
      else
        @proxy_pass
      end
    end

    def environment_variable_is_multiuser_safe?
      ENVIRONMENT_VARIABLE_IS_MULTIUSER_SAFE
    end
  end
end
