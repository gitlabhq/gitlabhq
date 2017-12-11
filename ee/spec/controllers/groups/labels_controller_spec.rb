require 'spec_helper'

describe Groups::LabelsController do
  let(:group) { create(:group) }
  let(:user)  { create(:user) }

  before do
    group.add_owner(user)

    sign_in(user)
  end

  describe 'GET #index' do
    subject { get :index, group_id: group.to_param }

    it_behaves_like 'disabled when using an external authorization service'
  end
end
