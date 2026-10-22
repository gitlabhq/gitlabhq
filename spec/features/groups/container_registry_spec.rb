# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Container Registry', :js, feature_category: :container_registry do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  before do
    group.add_owner(user)
    sign_in(user)
    stub_container_registry_config(enabled: true)
    stub_container_registry_tags(repository: :any, tags: [])
    stub_container_registry_info
    allow(ContainerRegistry::GitlabApiClient).to receive(:supports_gitlab_api?).and_return(true)
  end

  it 'sidebar menu is open' do
    visit group_container_registries_path(group)

    expect(page).to have_active_navigation('Deploy')
    expect(page).to have_active_sub_navigation('Container registry')
  end
end
