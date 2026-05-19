# frozen_string_literal: true

require "spec_helper"

RSpec.describe "User browses files history", :js, feature_category: :source_code_management do
  include RepoHelpers

  let_it_be(:project) { create(:project, :repository) }
  let(:tree_path_root_ref) { project_tree_path(project, project.repository.root_ref) }
  let(:user) { project.first_owner }

  before do
    sign_in(user)
  end

  describe "history navigation to commits page" do
    before do
      visit(tree_path_root_ref)
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

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('README.md')
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

    context "when project_commits_refactor is enabled" do
      before do
        stub_feature_flags(project_commits_refactor: true)
        visit(tree_path_root_ref)
      end

      it "shows the `Browse files` link in Actions dropdown for directory" do
        click_link("files")

        page.within('.repo-breadcrumb') do
          expect(page).to have_link('files')
        end

        click_link("History")

        history_path = project_commits_path(project, "master/files")
        expect(page).to have_current_path(history_path)

        click_button("Actions")
        expect(page).to have_link("Browse files")
      end

      it "shows the `Browse files` link in Actions dropdown for file" do
        page.within(".tree-table") do
          click_link("README.md")
        end

        page.within('.repo-breadcrumb') do
          expect(page).to have_link('README.md')
        end

        page.within(".commit-actions") do
          click_link("History")
        end

        history_path = project_commits_path(project, "master/README.md")
        expect(page).to have_current_path(history_path)

        click_button("Actions")
        expect(page).to have_link("Browse files")
      end

      it "shows the `Browse files` link in Actions dropdown for root" do
        click_link("History")

        history_path = project_commits_path(project, "master")
        expect(page).to have_current_path(history_path)

        click_button("Actions")
        expect(page).to have_link("Browse files")
      end
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

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('files')
      end

      click_link("History")

      history_path = project_commits_path(project, "v1.0.0/files")
      expect(page).to have_current_path(history_path)
    end

    it "shows history button that points to correct url for a file" do
      page.within(".tree-table") do
        click_link("README.md")
      end

      page.within('.repo-breadcrumb') do
        expect(page).to have_link('README.md')
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
end
