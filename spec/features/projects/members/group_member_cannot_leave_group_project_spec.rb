# frozen_string_literal: true

require 'spec_helper'

describe 'Projects > Members > Group member cannot leave group project' do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  before do
    group.add_developer(user)
    sign_in(user)
  end

  it 'user does not see a "Leave project" link' do
    visit project_path(project)

    expect(page).not_to have_content 'Leave project'
  end

  it 'renders a flash message if attempting to leave by url', :js do
    visit project_path(project, leave: 1)

    expect(find('.flash-alert')).to have_content 'You do not have permission to leave this project'
  end
end
