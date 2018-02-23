require 'spec_helper'

describe GroupsHelper do
  describe '#group_sidebar_links' do
    let(:user) { create(:user) }
    let(:group) { create(:group) }

    before do
      allow(helper).to receive(:current_user) { user }
      helper.instance_variable_set(:@group, group)
      allow(helper).to receive(:can?).with(user, :admin_group, group) { false }
    end

    it 'shows the licenced cross project features when the user can read cross project' do
      expect(helper).to receive(:can?).with(user, :read_cross_project).at_least(1) { true }
      stub_licensed_features(contribution_analytics: true,
                             group_issue_boards: true,
                             epics: true)

      expect(helper.group_sidebar_links).to include(:contribution_analytics, :boards, :epics)
    end
  end
end
