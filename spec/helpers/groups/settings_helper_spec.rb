# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::SettingsHelper do
  include GroupsHelper
  include NumbersHelper

  let_it_be(:group) { create(:group, path: "foo") }

  describe('#group_settings_confirm_modal_data') do
    using RSpec::Parameterized::TableSyntax

    fake_form_id = "fake_form_id"
    where(:prevent_delete_response, :is_button_disabled, :form_value_id) do
      true      | "true"      | nil
      true      | "true"      | fake_form_id
      false     | "false"     | nil
      false     | "false"     | fake_form_id
    end

    with_them do
      it "returns expected parameters" do
        allow(group).to receive(:prevent_delete?).and_return(prevent_delete_response)

        expected = helper.group_settings_confirm_modal_data(group, form_value_id)
        expect(expected).to eq({
          button_text: "Remove group",
          confirm_danger_message: remove_group_message(group),
          remove_form_id: form_value_id,
          phrase: group.full_path,
          button_testid: "remove-group-button",
          disabled: is_button_disabled,
          html_confirmation_message: 'true'
        })
      end
    end
  end
end
