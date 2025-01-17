# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User browses files", :js, feature_category: :source_code_management do
  include RepoHelpers
  include ListboxHelpers

  let(:fork_message) do
    "You're not allowed to make changes to this project directly. "\
    "A fork of this project has been created that you can make changes in, so you can submit a merge request."
  end

  let_it_be(:project) { create(:project, :repository) }
  let(:tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)

    stub_feature_flags(blob_overflow_menu: false)
  end

  it "shows last commit for current directory", :js do
    visit(tree_path_root_ref)

    click_link("files")

    last_commit = project.repository.last_commit_for_path(project.default_branch, "files")

    page.within(".commit-detail") do
      expect(page).to have_content(last_commit.short_id).and have_content(last_commit.author_name)
    end
  end

  context "when browsing a branch", :js do
    before do
      visit(tree_path_root_ref)
    end

    it "shows files from a repository" do
      expect(page).to have_content("VERSION")
                 .and have_content(".gitignore")
                 .and have_content("LICENSE")
    end

    it "shows the `Browse Directory` link" do
      click_link("files")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link("History")

      history_path = project_commits_path(project, "master/files")
      expect(page).to have_current_path(history_path)
      expect(page).to have_link("Browse Directory").and have_no_link("Browse Code")
    end

    it "shows the `Browse File` link" do
      page.within(".tree-table") do
        click_link("README.md")
      end

      page.within(".commit-actions") do
        click_link("History")
      end

      history_path = project_commits_path(project, "master/README.md")
      expect(page).to have_current_path(history_path)
      expect(page).to have_link("Browse File").and have_no_link("Browse Files")
    end

    it "shows the `Browse Files` link" do
      click_link("History")

      history_path = project_commits_path(project, "master")
      expect(page).to have_current_path(history_path)
      expect(page).to have_link("Browse Files").and have_no_link("Browse Directory")
    end

    it "redirects to the permalink URL" do
      click_link(".gitignore")
      click_link("Permalink")

      permalink_path = project_blob_path(project, "#{project.repository.commit.sha}/.gitignore")

      expect(page).to have_current_path(permalink_path, ignore_query: true)
    end
  end

  context "when browsing a tag", :js do
    before do
      visit(project_tree_path(project, "v1.0.0"))
    end

    it "shows history button that points to correct url" do
      click_link("History")

      history_path = project_commits_path(project, "v1.0.0")
      expect(page).to have_current_path(history_path)
    end

    it "shows history button that points to correct url for directory" do
      click_link("files")

      click_link("History")

      history_path = project_commits_path(project, "v1.0.0/files")
      expect(page).to have_current_path(history_path)
    end

    it "shows history button that points to correct url for a file" do
      page.within(".tree-table") do
        click_link("README.md")
      end

      click_link("History")

      history_path = project_commits_path(project, "v1.0.0/README.md")
      expect(page).to have_current_path(history_path)
    end
  end

  context "when browsing a commit", :js do
    let(:last_commit) { project.repository.last_commit_for_path(project.default_branch, "files") }

    before do
      visit(project_tree_path(project, last_commit))
    end

    it "shows history button that points to correct url" do
      click_link("History")

      history_path = project_commits_path(project, last_commit)
      expect(page).to have_current_path(history_path)
    end
  end

  context "when browsing the `markdown` branch", :js do
    context "when browsing the root" do
      before do
        visit(project_tree_path(project, "markdown"))
      end

      it "redirects to the permalink URL" do
        click_link(".gitignore")
        click_link("Permalink")

        permalink_path = project_blob_path(project, "#{project.repository.commit('markdown').sha}/.gitignore")

        expect(page).to have_current_path(permalink_path, ignore_query: true)
      end

      it "shows correct files and links" do
        expect(page).to have_current_path(project_tree_path(project, "markdown"), ignore_query: true)
        expect(page).to have_content("README.md")
          .and have_content("CHANGELOG")
          .and have_content("Welcome to GitLab GitLab is a free project and repository management application")
          .and have_link("GitLab API doc")
          .and have_link("GitLab API website")
          .and have_link("Rake tasks")
          .and have_link("backup and restore procedure")
          .and have_link("GitLab API doc directory")
          .and have_link("Maintenance")
          .and have_header_with_correct_id_and_link(2, "Application details", "application-details")
          .and have_link("empty", href: "")
          .and have_link("#id", href: "#id")
          .and have_link("/#id", href: project_blob_path(project, "markdown/README.md", anchor: "id"))
          .and have_link("README.md#id", href: project_blob_path(project, "markdown/README.md", anchor: "id"))
          .and have_link("d/README.md#id", href: project_blob_path(project, "markdown/db/README.md", anchor: "id"))
      end

      it "shows correct content of file" do
        click_link("GitLab API doc")

        expect(page).to have_current_path(project_blob_path(project, "markdown/doc/api/README.md"), ignore_query: true)
        expect(page).to have_content("All API requests require authentication")
          .and have_content("Contents")
          .and have_link("Users")
          .and have_link("Rake tasks")
          .and have_header_with_correct_id_and_link(1, "GitLab API", "gitlab-api")

        click_link("Users")

        expect(page).to have_current_path(project_blob_path(project, "markdown/doc/api/users.md"), ignore_query: true)
        expect(page).to have_content("Get a list of users.")

        page.go_back

        click_link("Rake tasks")

        expect(page).to have_current_path(project_tree_path(project, "markdown/doc/raketasks"), ignore_query: true)
        expect(page).to have_content("maintenance.md")

        click_link("maintenance.md")

        expect(page).to have_current_path(project_blob_path(project, "markdown/doc/raketasks/maintenance.md"), ignore_query: true)
        expect(page).to have_content("bundle exec rake gitlab:env:info RAILS_ENV=production")

        page.within(".tree-ref-container") do
          click_link(project.path)
        end

        page.within(".tree-table") do
          click_link("README.md")
        end

        page.go_back

        page.within(".tree-table") do
          click_link("d")
        end

        expect(page).to have_link("..", href: project_tree_path(project, "markdown"))

        page.within(".tree-table") do
          click_link("README.md")
        end

        expect(page).to have_link("empty", href: "")
      end

      it "shows correct content of directory" do
        click_link("GitLab API doc directory")

        expect(page).to have_current_path(project_tree_path(project, "markdown/doc/api"), ignore_query: true)
        expect(page).to have_content("README.md").and have_content("users.md")

        click_link("Users")

        expect(page).to have_current_path(project_blob_path(project, "markdown/doc/api/users.md"), ignore_query: true)
        expect(page).to have_content("List users").and have_content("Get a list of users.")
      end
    end
  end

  context 'when commit message has markdown', :js do
    before do
      project.repository.create_file(user, 'index', 'test', message: ':star: testing', branch_name: 'master')

      visit(project_tree_path(project, "master"))
    end

    it 'renders emojis' do
      expect(page).to have_selector('gl-emoji', count: 2)
    end
  end

  context "when browsing a `improve/awesome` branch", :js do
    before do
      visit(project_tree_path(project, "improve/awesome"))
    end

    it "shows files from a repository" do
      expect(page).to have_content("VERSION")
        .and have_content(".gitignore")
        .and have_content("LICENSE")

      click_link("files")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link("html")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('html')
      end

      expect(page).to have_link('500.html')
    end
  end

  context "when browsing a `Ääh-test-utf-8` branch", :js do
    before do
      project.repository.create_branch('Ääh-test-utf-8', project.repository.root_ref)
      visit(project_tree_path(project, "Ääh-test-utf-8"))
    end

    it "shows files from a repository" do
      expect(page).to have_content("VERSION")
        .and have_content(".gitignore")
        .and have_content("LICENSE")

      click_link("files")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link("html")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('html')
      end

      expect(page).to have_link('500.html')
    end
  end

  context "when browsing a `test-#` branch", :js do
    before do
      project.repository.create_branch('test-#', project.repository.root_ref)
      visit(project_tree_path(project, "test-#"))
    end

    it "shows files from a repository" do
      expect(page).to have_content("VERSION")
        .and have_content(".gitignore")
        .and have_content("LICENSE")

      click_link("files")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link("html")

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('html')
      end

      expect(page).to have_link('500.html')
    end
  end

  context "when browsing a specific ref", :js do
    let(:ref) { project_tree_path(project, "6d39438") }

    ref_selector = '.ref-selector'

    before do
      visit(ref)
    end

    it "shows files from a repository for `6d39438`" do
      expect(page).to have_current_path(ref, ignore_query: true)
      expect(page).to have_content(".gitignore").and have_content("LICENSE")
    end

    it "shows files from a repository with apostrophe in its name" do
      ref_name = 'fix'

      find(ref_selector).click
      wait_for_requests

      filter_by(ref_name)

      expect(find(ref_selector)).to have_text(ref_name)

      visit(project_tree_path(project, ref_name))

      expect(page).not_to have_selector(".tree-commit .animation-container")
    end

    it "shows the code with a leading dot in the directory" do
      ref_name = 'fix'

      find(ref_selector).click
      wait_for_requests

      filter_by(ref_name)

      visit(project_tree_path(project, "fix/.testdir"))

      expect(page).not_to have_selector(".tree-commit .animation-container")
    end
  end

  context "when browsing a file content", :js do
    before do
      visit(tree_path_root_ref)
      wait_for_requests

      click_link(".gitignore")
    end

    it "shows a file content" do
      expect(page).to have_content("*.rbc")
    end

    it "is possible to blame" do
      click_link("Blame")

      expect(page).to have_content("*.rb")
                 .and have_content("Dmitriy Zaporozhets")
                 .and have_content("Initial commit")
                 .and have_content("Ignore DS files")

      previous_commit_link = find('.tr', text: "Ignore DS files").find("[aria-label='View blame prior to this change']")
      previous_commit_link.click

      expect(page).to have_content("*.rb")
                 .and have_content("Dmitriy Zaporozhets")
                 .and have_content("Initial commit")

      expect(page).not_to have_content("Ignore DS files")
    end
  end

  context "when browsing a file with pathspec characters" do
    let(:filename) { ':wq' }
    let(:newrev) { project.repository.commit('master').sha }

    before do
      create_file_in_repo(project, 'master', 'master', filename, 'Test file')
      path = File.join('master', filename)

      visit(project_blob_path(project, path))
      wait_for_requests
    end

    it "shows raw file content in a new tab" do
      new_tab = window_opened_by { click_link 'Open raw' }

      within_window new_tab do
        expect(page).to have_content("Test file")
      end
    end
  end

  context "when browsing a raw file" do
    before do
      visit(tree_path_root_ref)
      wait_for_requests

      click_link(".gitignore")
      wait_for_requests
    end

    it "shows raw file content in a new tab" do
      new_tab = window_opened_by { click_link 'Open raw' }

      within_window new_tab do
        expect(page).to have_content("*.rbc")
      end
    end
  end

  def filter_by(filter_text)
    send_keys filter_text

    wait_for_requests

    select_listbox_item filter_text
  end
end
