# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Topic Feed", :with_current_organization, feature_category: :groups_and_projects do
  let_it_be(:topic) { create(:topic, name: 'test-topic', title: 'Test topic', organization: current_organization) }
  let_it_be(:empty_topic) { create(:topic, name: 'empty-topic', organization: current_organization) }
  let_it_be(:project1) { create(:project, :public, topic_list: topic.name, organization: current_organization) }
  let_it_be(:project2) { create(:project, :public, topic_list: topic.name, organization: current_organization) }

  context 'when topic does not exist' do
    let(:path) { topic_explore_projects_path(topic_name: 'non-existing', format: 'atom') }

    it 'renders 404' do
      visit path

      expect(status_code).to eq(404)
    end
  end

  context 'when topic exists' do
    before do
      visit topic_explore_projects_path(topic_name: topic.name, format: 'atom')
    end

    it "renders topic atom feed" do
      expect(body).to have_selector('feed title')
    end

    it "has project entries" do
      expect(body).to have_content(project1.name)
      expect(body).to have_content(project2.name)
    end
  end

  context 'when topic is empty' do
    before do
      visit topic_explore_projects_path(topic_name: empty_topic.name, format: 'atom')
    end

    it "renders topic atom feed" do
      expect(body).to have_selector('feed title')
    end

    it "has no project entry" do
      expect(body).to have_no_selector('entry')
    end
  end
end
