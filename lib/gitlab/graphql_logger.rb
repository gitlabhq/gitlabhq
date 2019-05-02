# frozen_string_literal: true

module Gitlab
  class GraphqlLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'graphql_json'
    end
  end
end
