require 'spec_helper'

describe Groups::VariablesController do
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  before do
    sign_in(user)
    group.add_master(user)
  end

  describe 'GET #show' do
    let!(:variable) { create(:ci_group_variable, group: group) }

    subject do
      get :show, group_id: group, format: :json
    end

    include_examples 'GET #show lists all variables'
  end

  describe 'PATCH #update' do
    let!(:variable) { create(:ci_group_variable, group: group) }
    let(:owner) { group }

    subject do
      patch :update,
        group_id: group,
        variables_attributes: variables_attributes,
        format: :json
    end

    include_examples 'PATCH #update updates variables'
  end
end
