# frozen_string_literal: true

module Gitlab
  class GraphqlLogger < Gitlab::Logger
    def self.file_name_noext
      'graphql_json'
    end

    # duration
    # complexity
    # depth
    # sanitized variables (?)
    # a structured representation of the query (?)

    def format_message(severity, timestamp, progname, msg)
      "#{timestamp.to_s(:long)}: #{msg}\n"
    end
  end
end
