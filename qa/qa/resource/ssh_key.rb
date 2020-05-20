# frozen_string_literal: true

module QA
  module Resource
    class SSHKey < Base
      extend Forwardable

      attr_reader :title

      attribute :id

      def_delegators :key, :private_key, :public_key, :md5_fingerprint

      def initialize
        self.title = Time.now.to_f
      end

      def key
        @key ||= Runtime::Key::RSA.new
      end

      def fabricate!
        Page::Main::Menu.perform(&:click_settings_link)
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
        QA::Runtime::Logger.debug("Deleting SSH key with title '#{title}' and fingerprint '#{md5_fingerprint}'")

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
          key: public_key
        }
      end

      def api_delete_path
        "/user/keys/#{id}"
      end
    end
  end
end
