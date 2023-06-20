# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group milestone', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group, owner: user) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }

  let(:milestone) { create(:milestone, group: group) }

  before do
    sign_in(user)
  end

  it_behaves_like 'milestone with interactive markdown task list items in description' do
    let(:milestone_path) { group_milestone_path(group, milestone) }
  end
end
