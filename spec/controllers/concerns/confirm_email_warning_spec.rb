# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ConfirmEmailWarning, feature_category: :system_access do
  before do
    stub_application_setting_enum('email_confirmation_setting', 'soft')
  end

  controller(ApplicationController) do
    # `described_class` is not available in this context
    include ConfirmEmailWarning

    def index
      head :ok
    end
  end

  RSpec::Matchers.define :set_confirm_warning_for do |email|
    match do |response|
      expect(controller).to set_flash.now[:warning].to include("Please check your email (#{email}) to verify that you own this address and unlock the power of CI/CD.")
    end
  end

  describe 'confirm email flash warning' do
    context 'when not signed in' do
      let(:user) { create(:user, confirmed_at: nil) }

      before do
        get :index
      end

      it { is_expected.not_to set_confirm_warning_for(user.email) }
    end

    context 'when signed in' do
      before do
        sign_in(user)
      end

      context 'with a confirmed user' do
        let(:user) { create(:user) }

        before do
          get :index
        end

        it { is_expected.not_to set_confirm_warning_for(user.email) }
      end

      context 'with an unconfirmed user' do
        let(:user) { create(:user, confirmed_at: nil) }

        context 'when executing a json request' do
          before do
            get :index, format: :json
          end

          it { is_expected.not_to set_confirm_warning_for(user.email) }
        end

        context 'when executing a post request' do
          before do
            post :index
          end

          it { is_expected.not_to set_confirm_warning_for(user.email) }
        end

        context 'when executing a get request' do
          before do
            get :index
          end

          context 'with an unconfirmed email address present' do
            let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: 'unconfirmed@gitlab.com') }

            it { is_expected.to set_confirm_warning_for(user.unconfirmed_email) }
          end

          context 'without an unconfirmed email address present' do
            it { is_expected.to set_confirm_warning_for(user.email) }
          end
        end

        context 'when user is being impersonated' do
          let(:impersonator) { create(:admin) }

          before do
            allow(controller).to receive(:session).and_return({ impersonator_id: impersonator.id })

            get :index
          end

          it { is_expected.to set_confirm_warning_for(user.email) }

          context 'when impersonated user email has html in their email' do
            let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: "malicious@test.com<form><input/title='<script>alert(document.domain)</script>'>") }

            it { is_expected.to set_confirm_warning_for("malicious@test.com&lt;form&gt;&lt;input/title=&#39;&lt;script&gt;alert(document.domain)&lt;/script&gt;&#39;&gt;") }
          end
        end

        context 'when user is not being impersonated' do
          before do
            get :index
          end

          it { is_expected.to set_confirm_warning_for(user.email) }

          context 'when user email has html in their email' do
            let(:user) { create(:user, confirmed_at: nil, unconfirmed_email: "malicious@test.com<form><input/title='<script>alert(document.domain)</script>'>") }

            it { is_expected.to set_confirm_warning_for("malicious@test.com&lt;form&gt;&lt;input/title=&#39;&lt;script&gt;alert(document.domain)&lt;/script&gt;&#39;&gt;") }
          end
        end
      end
    end
  end
end
