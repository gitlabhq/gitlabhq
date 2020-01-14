# frozen_string_literal: true

module QA
  module Resource
    class SSHKey < Base
      extend Forwardable

      attr_accessor :title

      def_delegators :key, :private_key, :public_key, :md5_fingerprint

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
    end
  end
end
