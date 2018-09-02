require 'spec_helper'

describe Groups::GroupLinksController do
  let(:group) { create(:group, :public) }
  # TODO(ifarkas): why does it need to be public?
  let(:shared_group) { create(:group, :public) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe '#create' do
    subject do
      post(:create,
           group_id: group,
           shared_group_id: shared_group.id,
           shared_group_access: GroupGroupLink.default_access)
    end

    context 'when user has access to group he want to link another group to' do
      before do
        group.add_developer(user)
        shared_group.add_developer(user)
      end

      it 'links group with selected group' do
        subject

        expect(group.shared_groups).to include shared_group
      end

      it 'redirects to group links page' do
        subject

        expect(response).to(redirect_to(group_group_members_path(group)))
      end
    end
  end
end
