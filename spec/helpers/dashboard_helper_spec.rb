require 'spec_helper'

describe DashboardHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#dashboard_nav_links' do
    it 'has all the expected links by default' do
      menu_items = [:projects, :groups, :activity, :milestones, :snippets]

      expect(helper.dashboard_nav_links).to contain_exactly(*menu_items)
    end

    it 'does not contain cross project elements when the user cannot read cross project' do
      expect(helper).to receive(:can?).with(user, :read_cross_project) { false }

      expect(helper.dashboard_nav_links).not_to include(:activity, :milestones)
    end
  end
end
