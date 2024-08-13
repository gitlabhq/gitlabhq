# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::TerraformHelper do
  describe '#js_terraform_list_data' do
    let_it_be(:project) { create(:project) }

    let(:current_user) { project.creator }

    subject { helper.js_terraform_list_data(current_user, project) }

    it 'includes image path' do
      image_path = ActionController::Base.helpers.image_path(
        'illustrations/empty-state/empty-environment-md.svg'
      )

      expect(subject[:empty_state_image]).to eq(image_path)
    end

    it 'includes project path' do
      expect(subject[:project_path]).to eq(project.full_path)
    end

    it 'includes access token path' do
      expect(subject[:access_tokens_path]).to eq(user_settings_personal_access_tokens_path)
    end

    it 'includes username' do
      expect(subject[:username]).to eq(current_user.username)
    end

    it 'includes terraform state api url' do
      expect(subject[:terraform_api_url]).to eq("#{Settings.gitlab.url}/api/v4/projects/#{project.id}/terraform/state")
    end

    it 'indicates the user is a terraform admin' do
      expect(subject[:terraform_admin]).to eq(true)
    end

    context 'when current_user is not a terraform admin' do
      let(:current_user) { create(:user) }

      it 'indicates the user is not an admin' do
        expect(subject[:terraform_admin]).to eq(false)
      end
    end

    context 'when current_user is missing' do
      let(:current_user) { nil }

      it 'indicates the user is not an admin' do
        expect(subject[:terraform_admin]).to be_nil
      end
    end
  end

  describe '#show_period_in_terraform_state_name_alert?' do
    let_it_be(:project) { create(:project) }

    context 'when user dismissed' do
      it 'returns false' do
        allow(helper).to receive(:show_period_in_terraform_state_name_alert_callout?).and_return(true)

        expect(helper.show_period_in_terraform_state_name_alert?(project)).to eq(false)
      end
    end

    context 'when user has not dismissed' do
      before do
        allow(helper).to receive(:show_period_in_terraform_state_name_alert_callout?).and_return(true)
      end

      context 'and terraform state exists' do
        it 'returns true' do
          allow(project.terraform_states).to receive(:exists?).and_return(true)

          expect(helper.show_period_in_terraform_state_name_alert?(project)).to eq(true)
        end
      end

      context 'and terraform state does not exist' do
        it 'returns false' do
          allow(project.terraform_states).to receive(:exists?).and_return(false)

          expect(helper.show_period_in_terraform_state_name_alert?(project)).to eq(false)
        end
      end
    end
  end
end
