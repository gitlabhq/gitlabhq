require 'spec_helper'

describe NamespacesHelper do
  let!(:admin) { create(:admin) }
  let!(:admin_group) { create(:group, :private) }
  let!(:user) { create(:user) }
  let!(:user_group) { create(:group, :private) }

  before do
    admin_group.add_owner(admin)
    user_group.add_owner(user)
  end

  describe '#namespaces_options' do
    it 'returns groups without being a member for admin' do
      allow(helper).to receive(:current_user).and_return(admin)

      options = helper.namespaces_options(user_group.id, display_path: true, extra_group: user_group.id)

      expect(options).to include(admin_group.name)
      expect(options).to include(user_group.name)
    end

    it 'returns only allowed namespaces for user' do
      allow(helper).to receive(:current_user).and_return(user)

      options = helper.namespaces_options

      expect(options).not_to include(admin_group.name)
      expect(options).to include(user_group.name)
    end
  end
end
