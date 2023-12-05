# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExploreHelper do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#public_visibility_restricted?' do
    it 'delegates to Gitlab::VisibilityLevel' do
      expect(Gitlab::VisibilityLevel).to receive(:public_visibility_restricted?).and_call_original

      helper.public_visibility_restricted?
    end
  end

  describe '#projects_filter_items' do
    let(:projects_filter_items) do
      [
        { href: '?', text: 'Any', value: 'Any' },
        { href: '?visibility_level=0', text: 'Private', value: 'Private' },
        { href: '?visibility_level=10', text: 'Internal', value: 'Internal' },
        { href: '?visibility_level=20', text: 'Public', value: 'Public' }
      ]
    end

    it 'returns correct dropdown items' do
      expect(helper.projects_filter_items).to eq(projects_filter_items)
    end
  end

  describe '#projects_filter_selected' do
    context 'when visibility_level is present' do
      it 'returns corresponding item' do
        expect(helper.projects_filter_selected('0')).to eq('Private')
      end
    end

    context 'when visibility_level is empty' do
      it 'returns corresponding item' do
        expect(helper.projects_filter_selected(nil)).to eq('Any')
      end
    end
  end
end
