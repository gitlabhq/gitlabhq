require 'gitlab/database'

module Gitlab
  module Database
    def self.serialized_transaction
      connection.transaction { yield }
    end
  end
end
