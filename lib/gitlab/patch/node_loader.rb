# frozen_string_literal: true

# Patch to address https://gitlab.com/gitlab-com/gl-infra/scalability/-/issues/2212#note_1287996694
# It uses hostname instead of IP address if the former is present in `CLUSTER NODES` output.
if Gem::Version.new(Redis::VERSION) > Gem::Version.new('4.8.1')
  raise 'New version of redis detected, please remove or update this patch'
end

module Gitlab
  module Patch
    module NodeLoader
      def self.prepended(base)
        base.class_eval do
          # monkey-patches https://github.com/redis/redis-rb/blob/v4.8.0/lib/redis/cluster/node_loader.rb#L23
          def self.fetch_node_info(node)
            node.call(%i[cluster nodes]).split("\n").map(&:split).to_h do |arr|
              [
                extract_host_identifier(arr[1]),
                (arr[2].split(',') & %w[master slave]).first # rubocop:disable Naming/InclusiveLanguage
              ]
            end
          end

          # Since `CLUSTER SLOT` uses the preferred endpoint determined by
          # the `cluster-preferred-endpoint-type` config value, we will prefer hostname over IP address.
          # See https://redis.io/commands/cluster-nodes/ for details on the output format.
          #
          # @param [String] Address info matching fhe format: <ip:port@cport[,hostname[,auxiliary_field=value]*]>
          def self.extract_host_identifier(node_address)
            ip_chunk, hostname, _auxiliaries = node_address.split(',')
            return ip_chunk.split('@').first if hostname.blank?

            port = ip_chunk.split('@').first.split(':')[1]
            "#{hostname}:#{port}"
          end
        end
      end
    end
  end
end
