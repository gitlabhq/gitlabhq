require 'spec_helper'

describe 'Reset namespace pipeline minutes' do
  let(:admin) { create(:admin) }

  before do
    sign_in(admin)
  end

  shared_examples 'resetting pipeline minutes' do
    context 'when namespace has namespace statistics' do
      before do
        namespace.create_namespace_statistics(shared_runners_seconds: 100)
      end

      it 'resets pipeline minutes' do
        click_link 'Reset pipeline minutes'

        expect(page).to have_selector('.flash-notice')
        expect(current_path).to include(namespace.name)

        expect(namespace.namespace_statistics.reload.shared_runners_seconds).to eq(0)
        expect(namespace.namespace_statistics.reload.shared_runners_seconds_last_reset).to be_like_time(Time.now)
      end
    end
  end

  shared_examples 'rendering error' do
    context 'when resetting pipeline minutes fails' do
      before do
        allow_any_instance_of(ClearNamespaceSharedRunnersMinutesService).to receive(:execute).and_return(false)
      end

      it 'renders edit page with an error' do
        click_link 'Reset pipeline minutes'

        expect(current_path).to include(namespace.name)
        expect(page).to have_selector('.flash-error')
      end
    end
  end

  describe 'for user namespace' do
    let(:user) { create(:user) }
    let(:namespace) { user.namespace }

    before do
      visit admin_user_path(user)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_link('Reset pipeline minutes', href: reset_runners_minutes_admin_user_path(user))
    end

    include_examples "resetting pipeline minutes"
    include_examples "rendering error"
  end

  describe 'when creating a new group' do
    before do
      visit admin_groups_path
      page.within '#content-body' do
        click_link "New group"
      end
    end

    it 'does not display reset pipeline minutes callout' do
      expect(page).not_to have_link('Reset pipeline minutes')
    end
  end

  describe 'for group namespace' do
    let(:group) { create(:group) }
    let(:namespace) { group }

    before do
      visit admin_group_path(group)
      click_link 'Edit'
    end

    it 'reset pipeline minutes button is visible' do
      expect(page).to have_link('Reset pipeline minutes', href: admin_group_reset_runners_minutes_path(group))
    end

    include_examples "resetting pipeline minutes"
    include_examples "rendering error"
  end
end
