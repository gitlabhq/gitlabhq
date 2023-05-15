# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Milestone editing", feature_category: :team_planning do
  let_it_be(:group) { create(:group, owner: user) }
  let_it_be(:user) { create(:group_member, :maintainer, user: create(:user), group: group).user }

  let(:milestone) { create(:milestone, group: group, title: "12345676543") }

  before do
    sign_in(user)

    visit(edit_group_milestone_path(group, milestone))
  end

  it_behaves_like 'milestone handling version conflicts'
end
