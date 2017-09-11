require 'spec_helper'

describe Admin::PushRulesController do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  describe '#update' do
    let(:params) do
      {
        deny_delete_tag: true, delete_branch_regex: "any", commit_message_regex: "any", branch_name_regex: "any",
        force_push_regex: "any", author_email_regex: "any", member_check: true, file_name_regex: "any",
        max_file_size: "0", prevent_secrets: true
      }
    end

    it 'updates sample push rule' do
      expect_any_instance_of(PushRule).to receive(:update_attributes).with(params)

      patch :update, push_rule: params

      expect(response).to redirect_to(admin_push_rule_path)
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'returns 404' do
        patch :update, push_rule: params

        expect(response).to have_http_status(404)
      end
    end
  end

  describe '#show' do
    it 'returns 200' do
      get :show

      expect(response).to have_http_status(200)
    end

    context 'push rules unlicensed' do
      before do
        stub_licensed_features(push_rules: false)
      end

      it 'returns 404' do
        get :show

        expect(response).to have_http_status(404)
      end
    end
  end
end
