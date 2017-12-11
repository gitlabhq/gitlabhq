require 'spec_helper'

describe NavHelper do
  describe '#header_links' do
    before do
      allow(helper).to receive(:session) { {} }
    end

    context 'when the user is logged in' do
      let(:user) { build(:user) }

      before do
        allow(helper).to receive(:current_user).and_return(user)
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

    it 'returns only the sign in and search when the user is not logged in' do
      allow(helper).to receive(:current_user).and_return(nil)
      allow(helper).to receive(:can?).with(nil, :read_cross_project) { true }

      expect(helper.header_links).to contain_exactly(:sign_in, :search)
    end
  end
end
