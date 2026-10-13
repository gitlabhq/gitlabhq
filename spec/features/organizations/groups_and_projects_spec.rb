# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Organization groups and projects', :js, feature_category: :organization do
  include ListboxHelpers

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, :organization_owner, organizations: [organization]) }
  let_it_be(:group) { create(:group, organization: organization, owners: user) }
  let_it_be(:project) { create(:project, namespace: group, organization: organization) }

  before do
    sign_in(user)
    visit groups_and_projects_organization_path(organization)
  end

  it 'lists groups and switches to projects' do
    expect(page).to have_link(group.name)

    select_from_listbox('Projects', from: 'Groups')

    expect(page).to have_link(project.name)
  end
end
