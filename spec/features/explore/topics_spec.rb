# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Explore Topics' do
  context 'when no topics exist' do
    it 'renders empty message', :aggregate_failures do
      visit topics_explore_projects_path

      expect(page).to have_current_path topics_explore_projects_path, ignore_query: true
      expect(page).to have_content('There are no topics to show.')
    end
  end

  context 'when topics exist' do
    let!(:topic) { create(:topic, name: 'topic1') }

    it 'renders topic list' do
      visit topics_explore_projects_path

      expect(page).to have_current_path topics_explore_projects_path, ignore_query: true
      expect(page).to have_content('topic1')
    end
  end
end
