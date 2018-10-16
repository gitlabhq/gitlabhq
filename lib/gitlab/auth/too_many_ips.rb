# frozen_string_literal: true

module Gitlab
  module Auth
    class TooManyIps < StandardError
      attr_reader :user_id, :ip, :unique_ips_count

      def initialize(user_id, ip, unique_ips_count)
        @user_id = user_id
        @ip = ip
        @unique_ips_count = unique_ips_count
      end

      def message
        "User #{user_id} from IP: #{ip} tried logging from too many ips: #{unique_ips_count}"
      end
    end
  end
end
