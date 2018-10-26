# frozen_string_literal: true

module QA
  module Factory
    module Resource
      class SSHKey < Factory::Base
        extend Forwardable

        def_delegators :key, :private_key, :public_key, :fingerprint

        attribute :private_key
        attribute :title
        attribute :fingerprint

        def key
          @key ||= Runtime::Key::RSA.new
        end

        def fabricate!
          Page::Main::Menu.perform(&:go_to_profile_settings)
          Page::Profile::Menu.perform(&:click_ssh_keys)

          Page::Profile::SSHKeys.perform do |page|
            page.add_key(public_key, title)
          end
        end
      end
    end
  end
end
