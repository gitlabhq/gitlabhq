# frozen_string_literal: true
module DependencyProxy
  URL_SUFFIX = '/dependency_proxy/containers'
  DISTRIBUTION_API_VERSION = 'registry/2.0'

  def self.table_name_prefix
    'dependency_proxy_'
  end
end
