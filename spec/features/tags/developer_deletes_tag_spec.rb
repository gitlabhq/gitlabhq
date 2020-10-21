# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer deletes tag', :js do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  before do
    project.add_developer(user)
    sign_in(user)
    visit project_tags_path(project)
  end

  context 'from the tags list page' do
    it 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      container = page.find('.content .flex-row', text: 'v1.1.0')
      delete_tag container

      expect(page).not_to have_content 'v1.1.0'
    end
  end

  context 'from a specific tag page' do
    it 'deletes the tag' do
      click_on 'v1.0.0'
      expect(current_path).to eq(
        project_tag_path(project, 'v1.0.0'))

      container = page.find('.nav-controls')
      delete_tag container

      expect(current_path).to eq("#{project_tags_path(project)}/")
      expect(page).not_to have_content 'v1.0.0'
    end
  end

  context 'when pre-receive hook fails' do
    before do
      allow_next_instance_of(Gitlab::GitalyClient::OperationService) do |instance|
        allow(instance).to receive(:rm_tag)
          .and_raise(Gitlab::Git::PreReceiveError, 'GitLab: Do not delete tags')
      end
    end

    it 'shows the error message' do
      container = page.find('.content .flex-row', text: 'v1.1.0')
      delete_tag container

      expect(page).to have_content('Do not delete tags')
    end
  end

  def delete_tag(container)
    container.find('.js-remove-tag').click

    page.within('.modal') { click_button('Delete tag') }
    wait_for_requests
  end
end
