require 'spec_helper'

describe Groups::TodosController do
  let(:user)   { create(:user) }
  let(:group)  { create(:group, :private) }
  let(:epic)   { create(:epic, group: group) }
  let(:parent) { group }

  describe 'POST create' do
    def post_create
      post :create,
        group_id: group,
        issuable_id: epic.id,
        issuable_type: 'epic',
        format: :json
    end

    it_behaves_like 'todos actions'
  end
end
