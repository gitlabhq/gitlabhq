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

  describe '#feature_entry' do
    context 'when implicitly enabled' do
      it 'considers feature enabled by default' do
        entry = feature_entry('Demo', href: 'demo.link')

        expect(entry).to include('<p aria-label="Demo: status on">')
        expect(entry).to include('<a href="demo.link">Demo</a>')
      end
    end

    context 'when explicitly enabled' do
      it 'returns a link' do
        entry = feature_entry('Demo', href: 'demo.link', enabled: true)

        expect(entry).to include('<p aria-label="Demo: status on">')
        expect(entry).to include('<a href="demo.link">Demo</a>')
      end

      it 'returns text if href is not provided' do
        entry = feature_entry('Demo', enabled: true)

        expect(entry).to include('<p aria-label="Demo: status on">')
        expect(entry).not_to match(/<a[^>]+>/)
      end
    end

    context 'when disabled' do
      it 'returns text without link' do
        entry = feature_entry('Demo', href: 'demo.link', enabled: false)

        expect(entry).to include('<p aria-label="Demo: status off">')
        expect(entry).not_to match(/<a[^>]+>/)
        expect(entry).to include('Demo')
      end
    end
  end

  describe '.has_start_trial?' do
    subject { helper.has_start_trial? }

    it { is_expected.to eq(false) }
  end
end
