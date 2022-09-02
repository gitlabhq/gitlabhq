# frozen_string_literal: true

module QA
  module Flow
    module Settings
      extend self

      def disable_snowplow
        Flow::Login.while_signed_in_as_admin do
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Admin::Menu.perform(&:go_to_general_settings)
          QA::Page::Admin::Settings::Component::Snowplow.perform(&:disable_snowplow_tracking)
        end
      end

      def enable_snowplow
        Flow::Login.while_signed_in_as_admin do
          QA::Page::Main::Menu.perform(&:go_to_admin_area)
          QA::Page::Admin::Menu.perform(&:go_to_general_settings)
          QA::Page::Admin::Settings::Component::Snowplow.perform(&:enable_snowplow_tracking)
        end
      end
    end
  end
end

QA::Flow::Settings.prepend_mod_with('Flow::Settings', namespace: QA)
