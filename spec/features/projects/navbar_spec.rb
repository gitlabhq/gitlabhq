# frozen_string_literal: true

require 'spec_helper'

describe 'Project navbar' do
  include NavbarStructureHelper

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in(user)
  end

  it_behaves_like 'verified navigation bar' do
    before do
      visit project_path(project)
    end
  end

  context 'when pages are available' do
    before do
      allow(Gitlab.config.pages).to receive(:enabled).and_return(true)

      insert_after_sub_nav_item(
        _('Operations'),
        within: _('Settings'),
        new_sub_nav_item_name: _('Pages')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
