require 'spec_helper'

describe 'Discussion Comments Epic', :js do
  let(:user) { create(:user) }
  let(:epic) { create(:epic) }

  before do
    stub_licensed_features(epics: true)
    epic.group.add_master(user)
    sign_in(user)

    visit group_epic_path(epic.group, epic)
  end

  it_behaves_like 'discussion comments', 'epic'
end
