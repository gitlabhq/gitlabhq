require 'spec_helper'

describe 'Group variables', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let!(:variable) { create(:ci_group_variable, key: 'test_key', value: 'test value', group: group) }
  let(:page_path) { group_settings_ci_cd_path(group) }

  before do
    group.add_maintainer(user)
    gitlab_sign_in(user)

    visit page_path
  end

  it_behaves_like 'variable list'
end
