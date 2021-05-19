# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Registrations::WelcomeController do
  let(:user) { create(:user) }

  describe '#welcome' do
    subject(:show) { get :show }

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'when role or setup_for_company is not set' do
      before do
        sign_in(user)
      end

      it { is_expected.to render_template(:show) }
    end

    context 'when role is required and setup_for_company is not set' do
      before do
        user.set_role_required!
        sign_in(user)
      end

      it { is_expected.to render_template(:show) }
    end

    context 'when role and setup_for_company is set' do
      before do
        user.update!(setup_for_company: false)
        sign_in(user)
      end

      it { is_expected.to redirect_to(dashboard_projects_path)}
    end

    context 'when role is set and setup_for_company is not set' do
      before do
        user.update!(role: :software_developer)
        sign_in(user)
      end

      it { is_expected.to render_template(:show) }
    end

    context '2FA is required from group' do
      before do
        user = create(:user, require_two_factor_authentication_from_group: true)
        sign_in(user)
      end

      it 'does not perform a redirect' do
        expect(subject).not_to redirect_to(profile_two_factor_auth_path)
      end
    end
  end

  describe '#update' do
    let(:email_opted_in) { '0' }

    subject(:update) do
      patch :update, params: { user: { role: 'software_developer', setup_for_company: 'false', email_opted_in: email_opted_in } }
    end

    context 'without a signed in user' do
      it { is_expected.to redirect_to new_user_registration_path }
    end

    context 'with a signed in user' do
      before do
        sign_in(user)
      end

      it { is_expected.to redirect_to(dashboard_projects_path)}

      context 'when the new user already has any accepted group membership' do
        let!(:member1) { create(:group_member, user: user) }

        it 'redirects to the group activity page' do
          expect(subject).to redirect_to(activity_group_path(member1.source))
        end

        context 'when the new user already has more than 1 accepted group membership' do
          it 'redirects to the most recent membership group activty page' do
            member2 = create(:group_member, user: user)

            expect(subject).to redirect_to(activity_group_path(member2.source))
          end
        end

        context 'when the member has an orphaned source at the time of the welcome' do
          it 'redirects to the project dashboard page' do
            member1.source.delete

            expect(subject).to redirect_to(dashboard_projects_path)
          end
        end
      end

      context 'when the user opted in' do
        let(:email_opted_in) { '1' }

        it 'sets the email_opted_in field' do
          subject

          expect(controller.current_user.email_opted_in).to eq(true)
        end
      end

      context 'when the user opted out' do
        it 'sets the email_opted_in field' do
          subject

          expect(controller.current_user.email_opted_in).to eq(false)
        end
      end
    end
  end
end
