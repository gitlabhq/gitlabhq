# frozen_string_literal: true

module CloudSeed
  module GoogleCloud
    class FetchGoogleIpListService
      include BaseServiceUtility

      GOOGLE_IP_RANGES_URL = 'https://www.gstatic.com/ipranges/cloud.json'
      RESPONSE_BODY_LIMIT = 1.megabyte
      EXPECTED_CONTENT_TYPE = 'application/json'

      IpListNotRetrievedError = Class.new(StandardError)

      def execute
        # Prevent too many workers from hitting the same HTTP endpoint
        if ::Gitlab::ApplicationRateLimiter.throttled?(:fetch_google_ip_list, scope: nil)
          return error("#{self.class} was rate limited")
        end

        subnets = fetch_and_update_cache!

        Gitlab::AppJsonLogger.info(
          class: self.class.name,
          message: 'Successfully retrieved Google IP list',
          subnet_count: subnets.count
        )

        success({ subnets: subnets })
      rescue IpListNotRetrievedError => err
        Gitlab::ErrorTracking.log_exception(err)
        error('Google IP list not retrieved')
      end

      private

      # Attempts to retrieve and parse the list of IPs from Google. Updates
      # the internal cache so that the data is accessible.
      #
      # Returns an array of IPAddr objects consisting of subnets.
      def fetch_and_update_cache!
        parsed_response = fetch_google_ip_list

        parse_google_prefixes(parsed_response).tap do |subnets|
          ::ObjectStorage::CDN::GoogleIpCache.update!(subnets)
        end
      end

      def fetch_google_ip_list
        response = Gitlab::HTTP.get(GOOGLE_IP_RANGES_URL, follow_redirects: false, allow_local_requests: false)

        validate_response!(response)

        response.parsed_response
      end

      def validate_response!(response)
        raise IpListNotRetrievedError, "response was #{response.code}" unless response.code == 200
        raise IpListNotRetrievedError, "response was nil" unless response.body

        parsed_response = response.parsed_response

        unless response.content_type == EXPECTED_CONTENT_TYPE && parsed_response.is_a?(Hash)
          raise IpListNotRetrievedError, "response was not JSON"
        end

        if response.body&.bytesize.to_i > RESPONSE_BODY_LIMIT
          raise IpListNotRetrievedError, "response was too large: #{response.body.bytesize}"
        end

        prefixes = parsed_response['prefixes']

        raise IpListNotRetrievedError, "JSON was type #{prefixes.class}, expected Array" unless prefixes.is_a?(Array)
        raise IpListNotRetrievedError, "#{GOOGLE_IP_RANGES_URL} did not return any IP ranges" if prefixes.empty?

        response.parsed_response
      end

      def parse_google_prefixes(parsed_response)
        ranges = parsed_response['prefixes'].map do |prefix|
          ip_range = prefix['ipv4Prefix'] || prefix['ipv6Prefix']

          next unless ip_range

          IPAddr.new(ip_range)
        end.compact

        raise IpListNotRetrievedError, "#{GOOGLE_IP_RANGES_URL} did not return any IP ranges" if ranges.empty?

        ranges
      end
    end
  end
end
