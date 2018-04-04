require 'spec_helper'

feature 'Protected Tags', :js do
  let(:user) { create(:user, :admin) }
  let(:project) { create(:project, :repository) }

  before do
    sign_in(user)
  end

  def set_allowed_to(operation, option = 'Masters', form: '.new-protected-tag')
    within form do
      find(".js-allowed-to-#{operation}").click
      wait_for_requests

      Array(option).each { |opt| click_on(opt) }

      find(".js-allowed-to-#{operation}").click # needed to submit form in some cases
    end
  end

  def set_protected_tag_name(tag_name)
    find(".js-protected-tag-select").click
    find(".dropdown-input-field").set(tag_name)
    click_on("Create wildcard #{tag_name}")
    find('.protected-tags-dropdown .dropdown-menu', visible: false)
  end

  describe "explicit protected tags" do
    it "allows creating explicit protected tags" do
      visit project_protected_tags_path(project)
      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('some-tag') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('some-tag')
    end

    it "displays the last commit on the matching tag if it exists" do
      commit = create(:commit, project: project)
      project.repository.add_tag(user, 'some-tag', commit.id)

      visit project_protected_tags_path(project)
      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content(commit.id[0..7]) }
    end

    it "displays an error message if the named tag does not exist" do
      visit project_protected_tags_path(project)
      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('tag was removed') }
    end
  end

  describe "wildcard protected tags" do
    it "allows creating protected tags with a wildcard" do
      visit project_protected_tags_path(project)
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('*-stable') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('*-stable')
    end

    it "displays the number of matching tags" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')

      visit project_protected_tags_path(project)
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on "Protect"

      within(".protected-tags-list") do
        expect(page).to have_content("Protected tag (2)")
        expect(page).to have_content("2 matching tags")
      end
    end

    it "displays all the tags matching the wildcard" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')
      project.repository.add_tag(user, 'development', 'master')

      visit project_protected_tags_path(project)
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on "Protect"

      visit project_protected_tags_path(project)
      click_on "2 matching tags"

      within(".protected-tags-list") do
        expect(page).to have_content("production-stable")
        expect(page).to have_content("staging-stable")
        expect(page).not_to have_content("development")
      end
    end
  end

  describe "access control" do
    describe 'with ref permissions for users enabled' do
      before do
        stub_licensed_features(protected_refs_for_users: true)
      end

      include_examples "protected tags > access control > EE"
    end

    describe 'with ref permissions for users disabled' do
      before do
        stub_licensed_features(protected_refs_for_users: false)
      end

      include_examples "protected tags > access control > CE"

      describe 'with existing access levels' do
        let(:protected_tag) { create(:protected_tag, project: project) }

        it 'shows users that can push to the branch' do
          protected_tag.create_access_levels.new(user: create(:user, name: 'Jane'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("The following user can also create tags: "\
                                       "Jane")
        end

        it 'shows groups that can create to the branch' do
          protected_tag.create_access_levels.new(group: create(:group, name: 'Team Awesome'))
            .save!(validate: false)

          visit project_settings_repository_path(project)

          expect(page).to have_content("Members of this group can also create tags: "\
                                       "Team Awesome")
        end
      end
    end
  end
end
