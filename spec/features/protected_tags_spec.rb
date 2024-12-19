# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Protected Tags', :js, :with_license, feature_category: :source_code_management,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/509488' do
  include ProtectedTagHelpers

  let(:project) { create(:project, :repository) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  describe "explicit protected tags" do
    it "allows creating explicit protected tags" do
      visit project_protected_tags_path(project)
      click_button('Add tag')

      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on_protect

      within(".protected-tags-list") { expect(page).to have_content('some-tag') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('some-tag')
    end

    it "displays the last commit on the matching tag if it exists" do
      commit = create(:commit, project: project)
      project.repository.add_tag(user, 'some-tag', commit.id)

      visit project_protected_tags_path(project)
      click_button('Add tag')
      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on_protect

      within(".protected-tags-list") { expect(page).to have_content(commit.id[0..7]) }
    end

    it "displays an error message if the named tag does not exist" do
      visit project_protected_tags_path(project)
      click_button('Add tag')
      set_protected_tag_name('some-tag')
      set_allowed_to('create')
      click_on_protect

      within(".protected-tags-list") { expect(page).to have_content('tag was removed') }
    end
  end

  describe "wildcard protected tags" do
    it "allows creating protected tags with a wildcard" do
      visit project_protected_tags_path(project)
      click_button('Add tag')
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on_protect

      within(".protected-tags-list") { expect(page).to have_content('*-stable') }
      expect(ProtectedTag.count).to eq(1)
      expect(ProtectedTag.last.name).to eq('*-stable')
    end

    it "displays the number of matching tags" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')

      visit project_protected_tags_path(project)
      click_button('Add tag')
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on_protect

      within('#js-protected-tags-settings [data-testid="crud-count"]') do
        expect(page).to have_content("2")
      end

      within(".protected-tags-list") do
        expect(page).to have_content("2 matching tags")
      end
    end

    it "displays all the tags matching the wildcard" do
      project.repository.add_tag(user, 'production-stable', 'master')
      project.repository.add_tag(user, 'staging-stable', 'master')
      project.repository.add_tag(user, 'development', 'master')

      visit project_protected_tags_path(project)
      click_button('Add tag')
      set_protected_tag_name('*-stable')
      set_allowed_to('create')
      click_on_protect

      visit project_protected_tags_path(project)
      click_button('Add tag')
      click_on "2 matching tags"

      within(".protected-tags-list") do
        expect(page).to have_content("production-stable")
        expect(page).to have_content("staging-stable")
        expect(page).not_to have_content("development")
      end
    end
  end

  describe "access control" do
    before do
      stub_licensed_features(protected_refs_for_users: false)
    end

    include_examples "protected tags > access control > CE"
  end

  context 'when the users for protected tags feature is off' do
    before do
      stub_licensed_features(protected_refs_for_users: false)
    end

    include_examples 'Deploy keys with protected tags' do
      let(:all_dropdown_sections) { ['Roles', 'Deploy keys'] }
    end
  end
end
