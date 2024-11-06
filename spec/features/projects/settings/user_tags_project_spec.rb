# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Settings > User tags a project', :js, feature_category: :groups_and_projects do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let!(:topic) { create(:topic, name: 'topic1', organization: project.organization) }

  before do
    sign_in(user)
    visit edit_project_path(project)
    wait_for_all_requests
  end

  it 'select existing topic' do
    fill_in class: 'gl-token-selector-input', with: 'topic1'
    wait_for_all_requests

    find('.gl-avatar-labeled[entity-name="topic1"]').click

    within_testid('general-settings-content') do
      click_button 'Save changes'
    end

    expect(find('#project_topic_list_field', visible: :hidden).value).to eq 'topic1'
  end

  it 'select new topic' do
    fill_in class: 'gl-token-selector-input', with: 'topic2'
    wait_for_all_requests

    click_button 'Add "topic2"'

    within_testid('general-settings-content') do
      click_button 'Save changes'
    end

    expect(find('#project_topic_list_field', visible: :hidden).value).to eq 'topic2'
  end
end
