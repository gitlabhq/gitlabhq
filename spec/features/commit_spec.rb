# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Commit', feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  shared_examples "single commit view" do
    let(:commit) do
      project.repository.commits(nil, limit: 100).find do |commit|
        commit.diffs.size > 1
      end
    end

    let(:files) { commit.diffs.diff_files.to_a }

    before do
      project.add_maintainer(user)
      sign_in(user)
    end

    describe "commit details" do
      subject { page }

      before do
        visit project_commit_path(project, commit)
      end

      it "shows the short commit message, number of total changes and stats", :js, :aggregate_failures do
        expect(page).to have_content(commit.title)
        expect(page).to have_content("Changes #{commit.diffs.size}")
        expect(page).to have_selector(".diff-stats")
      end

      it_behaves_like 'code highlight'
    end

    describe "pagination" do
      before do
        stub_const("Projects::CommitController::COMMIT_DIFFS_PER_PAGE", 1)

        visit project_commit_path(project, commit)
      end

      def diff_files_on_page
        page.all('.files .diff-file').pluck(:id)
      end

      it "shows paginated content and controls to navigate", :js, :aggregate_failures do
        expect(page).to have_content("Showing 1 changed file")

        wait_for_requests

        expect(diff_files_on_page).to eq([files[0].file_hash])

        within(".files .gl-pagination") do
          click_on("2")
        end

        wait_for_requests

        expect(diff_files_on_page).to eq([files[1].file_hash])
      end
    end
  end

  it_behaves_like "single commit view"
end
