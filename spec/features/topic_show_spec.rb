# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Topic show page', :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:current_organization, reload: true) { create(:organization, :public, name: 'Current Public Organization') }

  let_it_be(:topic) do
    create(
      :topic,
      name: 'my-topic',
      title: 'My Topic',
      description: 'This is **my** topic https://google.com/ :poop: ```\ncode\n```',
      avatar: fixture_file_upload("spec/fixtures/dk.png", "image/png"),
      organization: current_organization
    )
  end

  context 'when topic does not exist' do
    let(:path) { topic_explore_projects_path(topic_name: 'non-existing') }

    it 'renders 404' do
      visit path

      expect(status_code).to eq(404)
    end
  end

  context 'when topic exists' do
    before do
      visit topic_explore_projects_path(topic_name: topic.name)
    end

    it 'shows title, avatar and description as markdown' do
      expect(page).to have_content(topic.title)
      expect(page).not_to have_content(topic.name)
      expect(page).to have_selector('.gl-avatar.gl-avatar-s48')
      expect(find('.md')).to have_selector('p > strong')
      expect(find('.md')).to have_selector('p > a[rel]')
      expect(find('.md')).to have_selector('p > gl-emoji')
      expect(find('.md')).to have_selector('p > code')
    end

    context 'with associated projects' do
      let_it_be(:project) { create(:project, :public, topic_list: topic.name, organization: topic.organization) }

      it 'shows project list' do
        visit topic_explore_projects_path(topic_name: topic.name)

        expect(find('.projects-list .project-name')).to have_content(project.name)
      end
    end

    context 'without associated projects' do
      it 'shows correct empty state message' do
        expect(page).to have_content('Explore public groups to find projects to contribute to')
      end
    end
  end
end
