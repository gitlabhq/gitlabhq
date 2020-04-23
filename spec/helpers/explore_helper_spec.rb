# frozen_string_literal: true

require 'spec_helper'

describe ExploreHelper do
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
    using RSpec::Parameterized::TableSyntax

    where(:visibility_levels, :expected_status) do
      nil | nil
      [Gitlab::VisibilityLevel::PRIVATE] | false
      [Gitlab::VisibilityLevel::PRIVATE, Gitlab::VisibilityLevel::INTERNAL] | false
      [Gitlab::VisibilityLevel::PUBLIC] | true
    end

    with_them do
      before do
        stub_application_setting(restricted_visibility_levels: visibility_levels)
      end

      it 'returns the expected status' do
        expect(helper.public_visibility_restricted?).to eq(expected_status)
      end
    end
  end
end
