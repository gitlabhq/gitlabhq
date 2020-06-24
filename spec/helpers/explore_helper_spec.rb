# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExploreHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#explore_nav_links' do
    it 'has all the expected links by default' do
      menu_items = [:projects, :groups, :snippets]

      expect(helper.explore_nav_links).to contain_exactly(*menu_items)
    end
  end

  describe '#public_visibility_restricted?' do
    it 'delegates to Gitlab::VisibilityLevel' do
      expect(Gitlab::VisibilityLevel).to receive(:public_visibility_restricted?).and_call_original

      helper.public_visibility_restricted?
    end
  end
end
