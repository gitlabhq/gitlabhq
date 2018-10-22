# frozen_string_literal: true

module QA
  module Factory
    module Resource
      class SSHKey < Factory::Base
        extend Forwardable

        attr_accessor :title
        attr_reader :private_key, :public_key, :fingerprint
        def_delegators :key, :private_key, :public_key, :fingerprint

        product :private_key
        product :title
        product :fingerprint

        def key
          @key ||= Runtime::Key::RSA.new
        end

        def fabricate!
          Page::Main::Menu.act { go_to_profile_settings }
          Page::Profile::Menu.act { click_ssh_keys }

          Page::Profile::SSHKeys.perform do |page|
            page.add_key(public_key, title)
          end
        end
      end
    end
  end
end
