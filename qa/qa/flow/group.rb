# frozen_string_literal: true

module QA
  module Flow
    module Group
      extend self

      def update_to_ultimate(group)
        Page::Main::Menu.perform(&:go_to_admin_area)
        Page::Admin::Menu.perform(&:go_to_groups_overview)

        Page::Admin::Overview::Groups::Index.perform do |index|
          index.search_group(group.name)
          index.click_group(group.name)
        end

        return unless EE::Page::Admin::Overview::Groups::Show.perform(&:group_plan) != 'Ultimate'

        Page::Admin::Overview::Groups::Show.perform(&:click_edit_group_link)

        Page::Admin::Overview::Groups::Edit.perform do |edit|
          edit.select_plan('Ultimate')
          edit.click_save_changes_button
        end
      end

      def enable_experimental_and_beta_features(group)
        group.visit!
        Page::Group::Menu.perform(&:go_to_general_settings)
        Page::Group::Settings::General.perform(&:set_use_experimental_features_enabled)
      end
    end
  end
end
