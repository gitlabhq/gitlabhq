require_relative 'storage_check/cli'
require_relative 'storage_check/gitlab_caller'
require_relative 'storage_check/option_parser'
require_relative 'storage_check/response'

module Gitlab
  module StorageCheck
    ENDPOINT = '/-/storage_check'.freeze
    Options = Struct.new(:target, :token, :interval, :dryrun)
  end
end
