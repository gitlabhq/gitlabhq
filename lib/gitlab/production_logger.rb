module Gitlab
  class ProductionLogger < Gitlab::Logger
    def self.file_name_noext
      'production'
    end
  end
end
