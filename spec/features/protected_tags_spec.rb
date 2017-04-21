require 'spec_helper'
Dir["./spec/features/protected_tags/*.rb"].sort.each { |f| require f }

feature 'Projected Tags', feature: true, js: true do
  let(:user) { create(:user, :admin) }
  let(:project) { create(:project) }

  before { login_as(user) }

  def set_protected_tag_name(tag_name)
    find(".js-protected-tag-select").click
    find(".dropdown-input-field").set(tag_name)
    click_on("Create wildcard #{tag_name}")
  end

  describe "explicit protected tags" do
    it "allows creating explicit protected tags" do
      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('some-tag')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('some-tag') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('some-tag')
    end

    it "displays the last commit on the matching tag if it exists" do
      commit = create(:commit, project: project)
      project.repository.add_tag(user, 'some-tag', commit.id)

      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('some-tag')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content(commit.id[0..7]) }
    end

    it "displays an error message if the named tag does not exist" do
      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('some-tag')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('tag was removed') }
    end
  end

  describe "wildcard protected tags" do
    it "allows creating protected tags with a wildcard" do
      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('*-stable')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content('*-stable') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('*-stable')
    end

    it "displays the number of matching tags" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')

      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('*-stable')
      click_on "Protect"

      within(".protected-tags-list") { expect(page).to have_content("2 matching tags") }
    end

    it "displays all the tags matching the wildcard" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')
      project.repository.add_tag(user, 'development', 'master')

      visit namespace_project_protected_tags_path(project.namespace, project)
      set_protected_tag_name('*-stable')
      click_on "Protect"

      visit namespace_project_protected_tags_path(project.namespace, project)
      click_on "2 matching tags"

      within(".protected-tags-list") do
        expect(page).to have_content("production-stable")
        expect(page).to have_content("staging-stable")
        expect(page).not_to have_content("development")
      end
    end
  end

  describe "access control" do
    include_examples "protected tags > access control > CE"
  end
end
