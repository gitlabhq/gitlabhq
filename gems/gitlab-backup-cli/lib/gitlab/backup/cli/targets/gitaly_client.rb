# frozen_string_literal: true

module Gitlab
  module Backup
    module Cli
      module Targets
        class GitalyClient
          attr_reader :storages, :gitaly_token

          def initialize(storages, gitaly_token)
            @storages = storages
            @gitaly_token = gitaly_token
          end

          def connection_data(storage)
            raise "storage not found: #{storage.inspect}" if storages[storage].nil?

            { 'address' => address(storage), 'token' => token(storage) }
          end

          private

          def address(storage)
            address = storages[storage]['gitaly_address']
            raise "storage #{storage.inspect} is missing a gitaly_address" unless address.present?

            unless %w[tcp unix tls dns].include?(URI(address).scheme)
              raise "Unsupported Gitaly address: " \
                    "#{address.inspect} does not use URL scheme 'tcp' or 'unix' or 'tls' or 'dns'"
            end

            address
          end

          def token(storage)
            storages[storage]['gitaly_token'].presence || gitaly_token
          end
        end
      end
    end
  end
end
