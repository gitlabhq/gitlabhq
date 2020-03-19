# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class ClientLogger < Gitlab::Logger
      def self.file_name_noext
        'sidekiq_client'
      end
    end
  end
end
