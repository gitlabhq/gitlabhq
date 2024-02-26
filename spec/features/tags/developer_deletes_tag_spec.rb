# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Developer deletes tag', :js, feature_category: :source_code_management do
  include Spec::Support::Helpers::ModalHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, :repository, namespace: group) }

  before do
    project.add_developer(user)
    sign_in(user)
    create(:protected_tag, project: project, name: 'v1.1.1')
    visit project_tags_path(project)
  end

  context 'from the tags list page' do
    it 'deletes the tag' do
      expect(page).to have_content 'v1.1.0'

      container = find_by_testid('tag-row', text: 'v1.1.0')
      delete_tag container

      expect(page).not_to have_content 'v1.1.0'
    end

    context 'protected tags' do
      it 'can not delete protected tags' do
        expect(page).to have_content 'v1.1.1'

        container = find_by_testid('tag-row', text: 'v1.1.1')
        expect(container).to have_button('Only a project maintainer or owner can delete a protected tag',
          disabled: true)
      end
    end
  end

  context 'from a specific tag page' do
    it 'deletes the tag' do
      click_on 'v1.0.0'
      expect(page).to have_current_path(
        project_tag_path(project, 'v1.0.0'), ignore_query: true)

      delete_tag

      expect(page).to have_current_path(project_tags_path(project), ignore_query: true)
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
      container = find_by_testid('tag-row', text: 'v1.1.0')
      delete_tag container

      expect(page).to have_content('Do not delete tags')
    end
  end

  def delete_tag(container = page.document)
    within container do
      click_button('Delete tag')
    end

    within_modal do
      click_button('Yes, delete tag')
    end

    wait_for_requests
  end
end
