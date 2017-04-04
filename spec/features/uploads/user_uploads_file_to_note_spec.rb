require 'rails_helper'

feature 'User uploads file to note', feature: true do
  include DropzoneHelper

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, creator: user, namespace: user.namespace) }

  scenario 'they see the attached file', js: true do
    issue = create(:issue, project: project, author: user)

    login_as(user)
    visit namespace_project_issue_path(project.namespace, project, issue)

    dropzone_file(Rails.root.join('spec', 'fixtures', 'dk.png'))
    click_button 'Comment'
    wait_for_ajax

    expect(find('a.no-attachment-icon img[alt="dk"]')['src'])
      .to match(%r{/#{project.full_path}/uploads/\h{32}/dk\.png$})
  end
end
