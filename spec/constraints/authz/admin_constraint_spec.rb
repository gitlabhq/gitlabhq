# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::AdminConstraint, feature_category: :system_access do
  let_it_be(:user) { create(:user) }
  let(:session) { {} }
  let(:warden) { instance_double(Warden::Proxy, authenticate?: true, user: user) }
  let(:request) { instance_double(ActionDispatch::Request, session: session, env: { 'warden' => warden }) }

  around do |example|
    Gitlab::Session.with_session(session) do
      example.run
    end
  end

  describe '#matches' do
    subject(:matches) { described_class.new.matches?(request) }

    context 'when application setting :admin_mode is enabled' do
      context 'when user is a regular user' do
        it 'forbids access' do
          expect(matches).to be(false)
        end
      end

      context 'when user is an admin' do
        let_it_be(:user) { create(:admin) }

        context 'when admin mode is disabled' do
          it 'forbids access' do
            expect(matches).to be(false)
          end
        end

        context 'when admin mode is enabled' do
          before do
            current_user_mode = Gitlab::Auth::CurrentUserMode.new(user)
            current_user_mode.request_admin_mode!
            current_user_mode.enable_admin_mode!(password: user.password)
          end

          it 'allows access' do
            expect(matches).to be(true)
          end
        end
      end
    end

    context 'when application setting :admin_mode is disabled' do
      before do
        stub_application_setting(admin_mode: false)
      end

      context 'when user is a regular user' do
        it 'forbids access' do
          expect(matches).to be(false)
        end
      end

      context 'when user is an admin' do
        let_it_be(:user) { create(:admin) }

        it 'allows access' do
          expect(matches).to be(true)
        end
      end
    end
  end
end
