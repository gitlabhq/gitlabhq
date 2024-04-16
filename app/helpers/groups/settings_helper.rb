# frozen_string_literal: true

module Groups
  module SettingsHelper
    include GroupsHelper

    def group_settings_confirm_modal_data(group, remove_form_id = nil)
      {
        remove_form_id: remove_form_id,
        button_text: _('Remove group'),
        button_testid: 'remove-group-button',
        disabled: group.prevent_delete?.to_s,
        confirm_danger_message: remove_group_message(group),
        phrase: group.full_path,
        html_confirmation_message: 'true'
      }
    end
  end
end

Groups::SettingsHelper.prepend_mod_with('Groups::SettingsHelper')
