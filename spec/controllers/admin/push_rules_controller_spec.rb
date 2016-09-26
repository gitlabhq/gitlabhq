require 'spec_helper'

describe Admin::PushRulesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#update' do
    it 'updates sample push rule' do
      params =
        { deny_delete_tag: true, delete_branch_regex: "any", commit_message_regex: "any",
          force_push_regex: "any", author_email_regex: "any", member_check: true, file_name_regex: "any",
          max_file_size: "0", prevent_secrets: true
        }

      expect_any_instance_of(PushRule).to receive(:update_attributes).with(params)

      patch :update, push_rule: params

      expect(response).to redirect_to(admin_push_rule_path)
    end
  end
end
