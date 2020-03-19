# frozen_string_literal: true

# https://gitlab.com/gitlab-org/gitlab/issues/207937
# http-cookie is not thread-safe while loading it the first time, see:
# https://github.com/sparklemotion/http-cookie/issues/6#issuecomment-543570876
# If we're using it, we should eagerly load it.
# For now, we have an implicit dependency on it via:
# * http
# * rest-client
require 'http/cookie_jar/hash_store' if Gem.loaded_specs.key?('http-cookie')
