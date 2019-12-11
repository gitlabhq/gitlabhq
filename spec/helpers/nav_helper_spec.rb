# frozen_string_literal: true

require 'spec_helper'

describe NavHelper, :do_not_mock_admin_mode do
  describe '#header_links' do
    include_context 'custom session'

    before do
      allow(helper).to receive(:session).and_return(session)
    end

    context 'when the user is logged in' do
      let(:user) { create(:user) }
      let(:current_user_mode) { Gitlab::Auth::CurrentUserMode.new(user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
        allow(helper).to receive(:current_user_mode).and_return(current_user_mode)
        allow(helper).to receive(:can?) { true }
      end

      it 'has all the expected links by default' do
        menu_items = [:user_dropdown, :search, :issues, :merge_requests, :todos]

        expect(helper.header_links).to contain_exactly(*menu_items)
      end

      it 'contains the impersonation link while impersonating' do
        expect(helper).to receive(:session) { { impersonator_id: 1 } }

        expect(helper.header_links).to include(:admin_impersonation)
      end

      context 'as admin' do
        let(:user) { create(:user, :admin) }

        context 'feature flag :user_mode_in_session is enabled' do
          it 'does not contain the admin mode link by default' do
            expect(helper.header_links).not_to include(:admin_mode)
          end

          context 'with admin mode enabled' do
            before do
              current_user_mode.request_admin_mode!
              current_user_mode.enable_admin_mode!(password: user.password)
            end

            it 'contains the admin mode link' do
              expect(helper.header_links).to include(:admin_mode)
            end
          end
        end

        context 'feature flag :user_mode_in_session is disabled' do
          before do
            stub_feature_flags(user_mode_in_session: false)
          end

          it 'does not contain the admin mode link' do
            expect(helper.header_links).not_to include(:admin_mode)
          end

          context 'with admin mode enabled' do
            before do
              current_user_mode.request_admin_mode!
              current_user_mode.enable_admin_mode!(password: user.password)
            end

            it 'has no effect on header links' do
              expect(helper.header_links).not_to include(:admin_mode)
            end
          end
        end
      end

      context 'when the user cannot read cross project' do
        before do
          allow(helper).to receive(:can?).with(user, :read_cross_project) { false }
        end

        it 'does not contain cross project elements when the user cannot read cross project' do
          expect(helper.header_links).not_to include(:issues, :merge_requests, :todos, :search)
        end

        it 'shows the search box when the user cannot read cross project and he is visiting a project' do
          helper.instance_variable_set(:@project, create(:project))

          expect(helper.header_links).to include(:search)
        end
      end
    end

    context 'when the user is not logged in' do
      let(:current_user_mode) { Gitlab::Auth::CurrentUserMode.new(nil) }

      before do
        allow(helper).to receive(:current_user).and_return(nil)
        allow(helper).to receive(:current_user_mode).and_return(current_user_mode)
        allow(helper).to receive(:can?).with(nil, :read_cross_project) { true }
      end

      it 'returns only the sign in and search when the user is not logged in' do
        expect(helper.header_links).to contain_exactly(:sign_in, :search)
      end
    end
  end

  context '.admin_monitoring_nav_links' do
    subject { helper.admin_monitoring_nav_links }

    it { is_expected.to all(be_a(String)) }
  end

  context '.group_issues_sub_menu_items' do
    subject { helper.group_issues_sub_menu_items }

    it { is_expected.to all(be_a(String)) }
  end
end
