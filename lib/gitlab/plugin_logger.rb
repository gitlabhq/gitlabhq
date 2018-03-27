module Gitlab
  class PluginLogger < Gitlab::Logger
    def self.file_name_noext
      'plugin'
    end
  end
end
