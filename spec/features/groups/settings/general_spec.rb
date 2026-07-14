# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group settings > General', :with_current_organization, feature_category: :groups_and_projects do
  include Spec::Support::Helpers::ModalHelpers
  include Features::WebIdeSpecHelpers

  let_it_be(:user) { create(:user, organization: current_organization) }
  let_it_be_with_reload(:group) { create(:group, path: 'foo', owners: [user]) }

  before do
    sign_in(user)
  end

  describe 'project creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Minimum role required to create projects')
    end
  end

  describe 'subgroup creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Roles allowed to create subgroups')
    end
  end

  describe 'edit group avatar' do
    before do
      visit edit_group_path(group)

      attach_file(:group_avatar, Rails.root.join('spec/fixtures/banana_sample.gif'))

      expect { save_general_group }.to change { group.reload.avatar? }.to(true) # rubocop:disable RSpec/ExpectInHook -- pre-existing violation
    end

    it 'uploads new group avatar', :aggregate_failures do
      expect(group.avatar).to be_instance_of AvatarUploader
      expect(group.avatar.url).to eq "/uploads/-/system/group/avatar/#{group.id}/banana_sample.gif"
      expect(page).to have_link('Remove avatar')
    end

    it 'removes group avatar' do
      expect { click_link 'Remove avatar' }.to change { group.reload.avatar? }.to(false)
      expect(page).not_to have_link('Remove avatar')
    end
  end

  describe 'edit group path' do
    it 'has a root URL label for top-level group' do
      visit edit_group_path(group)

      expect(find(:css, '.group-root-path').text).to eq(unscoped_root_url)
    end

    context 'with scoped paths' do
      before do
        allow(current_organization).to receive(:scoped_paths?).and_return(true)
      end

      it 'has a parent group URL label for a subgroup group' do
        subgroup = create(:group, parent: group)

        visit edit_group_path(subgroup)

        expect(find(:css, '.group-root-path').text).to eq("#{group_url(subgroup.parent)}/")
      end
    end

    context 'without scoped paths' do
      before do
        allow(current_organization).to receive(:scoped_paths?).and_return(false)
      end

      it 'has a parent group URL label for a subgroup group' do
        subgroup = create(:group, parent: group)

        visit edit_group_path(subgroup)

        expect(find(:css, '.group-root-path').text).to eq("#{group_url(subgroup.parent)}/")
      end
    end
  end

  describe 'group README', :js do
    context 'with gitlab-profile project and README.md' do
      let_it_be(:project) { create(:project, :readme, namespace: group) }

      it 'renders link to Group README and navigates to it on click' do
        visit edit_group_path(group)

        expect(page).to have_link('README')

        click_link('README')

        expect(page).to have_current_path(project_blob_path(project, "#{project.default_branch}/README.md"))
        expect(page).to have_text('README.md')
      end
    end

    context 'with gitlab-profile project and no README.md' do
      let_it_be(:project) { create(:project, path: 'gitlab-profile', namespace: group) }

      it 'renders Add README button and allows user to create a README via the IDE' do
        visit edit_group_path(group)

        expect(page).to have_button('Add README')
        expect(page).not_to have_selector('.ide')

        click_button('Add README')

        readme_project_path = group.readme_project.present.path_with_namespace
        accept_gl_confirm("This will create a README.md for project #{readme_project_path}.", button_text: 'Add README')

        expect(page).to have_current_path("/-/ide/project/#{readme_project_path}/edit/main/-/README.md/")

        within_web_ide do
          expect(page).to have_text('README.md')
        end
      end
    end

    context 'with no gitlab-profile project and no README.md' do
      it 'renders Add README button and allows user to create both the gitlab-profile project and README via the IDE' do
        visit edit_group_path(group)

        expect(page).to have_button('Add README')
        expect(page).not_to have_selector('.ide')

        click_button('Add README')

        accept_gl_confirm(
          "This will create a project #{group.full_path}/gitlab-profile and add a README.md.",
          button_text: 'Create and add README'
        )

        expect(page).to have_current_path("/-/ide/project/#{group.full_path}/gitlab-profile/edit/main/-/README.md/")

        within_web_ide do
          expect(page).to have_text('README.md')
        end
      end
    end
  end

  def save_general_group
    within_testid('general-settings') do
      click_button 'Save changes'
    end
  end
end
