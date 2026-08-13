# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExploreHelper, feature_category: :groups_and_projects do
  let(:user) { build(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
    allow(helper).to receive(:can?) { true }
  end

  describe '#filter_projects_path' do
    before do
      helper.params.merge!(name: 'search term', language: '1', language_name: 'C++')
    end

    it 'preserves and encodes the language name while ignoring the legacy language ID' do
      expect(helper.filter_projects_path).to eq('?language_name=C%2B%2B&name=search+term')
    end

    it 'supports explicitly clearing the language name and project name' do
      expect(helper.filter_projects_path(language_name: nil, name: nil)).to eq('?')
    end
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

  describe '#explore_projects_app_data' do
    it 'returns the correct data hash' do
      expect(helper.explore_projects_app_data).to eq({
        initial_sort: 'created_desc',
        programming_languages: ProgrammingLanguage.most_popular.to_json,
        base_path: '/explore/projects'
      })
    end
  end

  describe '#explore_groups_app_data' do
    it 'returns the correct data hash' do
      expect(helper.explore_groups_app_data).to eq({
        endpoint: '/explore/groups.json',
        initial_sort: 'id_desc',
        base_path: '/explore/groups'
      })
    end
  end
end
