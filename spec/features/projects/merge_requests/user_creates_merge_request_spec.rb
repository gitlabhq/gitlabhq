require 'spec_helper'

describe 'User creates a merge request', :js do
<<<<<<< HEAD
  let(:project) do
    create(:project,
      :repository,
      approvals_before_merge: 1,
      merge_requests_template: 'This merge request should contain the following.')
  end
  let(:user) { create(:user) }
  let(:user2) { create(:user) }
=======
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }
>>>>>>> ce-com/master

  before do
    project.add_master(user)
    sign_in(user)

<<<<<<< HEAD
    project.approvers.create(user_id: user.id)

=======
>>>>>>> ce-com/master
    visit(project_new_merge_request_path(project))
  end

  it 'creates a merge request' do
<<<<<<< HEAD
    allow_any_instance_of(Gitlab::AuthorityAnalyzer).to receive(:calculate).and_return([user2])

=======
>>>>>>> ce-com/master
    find('.js-source-branch').click
    click_link('fix')

    find('.js-target-branch').click
    click_link('feature')

    click_button('Compare branches')

<<<<<<< HEAD
    expect(find_field('merge_request_description').value).to eq('This merge request should contain the following.')

    # Approvers
    page.within('ul .unsaved-approvers') do
      expect(page).to have_content(user.name)
    end

    page.within('.suggested-approvers') do
      expect(page).to have_content(user2.name)
    end

    click_link(user2.name)

    page.within('ul.approver-list') do
      expect(page).to have_content(user2.name)
    end
    # End of approvers

=======
>>>>>>> ce-com/master
    fill_in('merge_request_title', with: 'Wiki Feature')
    click_button('Submit merge request')

    page.within('.merge-request') do
      expect(page).to have_content('Wiki Feature')
    end

<<<<<<< HEAD
    # wait_for_requests

    page.within('.issuable-actions') do
      click_link('Edit', match: :first)
    end

    page.within('ul.approver-list') do
      expect(page).to have_content(user2.name)
    end
=======
    wait_for_requests
>>>>>>> ce-com/master
  end
end
