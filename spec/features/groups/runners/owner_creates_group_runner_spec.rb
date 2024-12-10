# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Group owner creates group runner", :js, feature_category: :fleet_visibility do
  let_it_be(:group_owner) { create(:user) }
  let_it_be(:group) { create(:group, owners: group_owner) }

  before do
    sign_in(group_owner)

    visit new_group_runner_path(group)
  end

  it_behaves_like 'creates runner and shows register page' do
    let(:register_path_pattern) { register_group_runner_path(group, '.*') }
  end
end
