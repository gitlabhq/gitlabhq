# frozen_string_literal: true

module QA
  module Resource
    class SSHKey < Base
      attr_reader :title
      attr_accessor :expires_at

      attribute :id

      delegate :private_key, :public_key, :md5_fingerprint, :sha256_fingerprint, to: :key

      def initialize
        self.title = Time.now.to_f
        @expires_at = Date.today + 2
      end

      def key
        @key ||= Runtime::Key::RSA.new
      end

      def fabricate!
        Page::Main::Menu.perform(&:click_edit_profile_link)
        Page::Profile::Menu.perform(&:click_ssh_keys)

        Page::Profile::SSHKeys.perform do |profile_page|
          profile_page.add_key(public_key, title)
        end
      end

      def fabricate_via_api!
        api_post
      end

      def title=(title)
        @title = "E2E test key: #{title}"
      end

      def api_delete
        QA::Runtime::Logger.debug("Deleting SSH key with title '#{title}' and fingerprint '#{sha256_fingerprint}'")

        super
      end

      def api_get_path
        "/user/keys/#{id}"
      end

      def api_post_path
        '/user/keys'
      end

      def api_post_body
        {
          title: title,
          key: public_key,
          expires_at: expires_at
        }
      end

      def api_delete_path
        "/user/keys/#{id}"
      end

      def accessible_on_secondary?
        api_client = Runtime::API::Client.new(:geo_secondary)

        QA::Runtime::Logger.debug('Checking for SSH key on secondary Geo site')

        Support::Retrier.retry_until(max_duration: QA::EE::Runtime::Geo.max_db_replication_time, sleep_interval: 3) do
          response = get Runtime::API::Request.new(api_client, api_get_path).url

          response.code == QA::Support::API::HTTP_STATUS_OK &&
            parse_body(response)[:title].include?(title)
        end
      end

      private

      def api_get
        with_paginated_response_body(Runtime::API::Request.new(api_client, '/user/keys', per_page: '100').url) do |page|
          key = page.find { |key| key[:title] == title }
          break process_api_response(key) if key
        end
      end
    end
  end
end
