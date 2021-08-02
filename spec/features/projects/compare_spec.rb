# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Compare", :js do
  let(:user)    { create(:user) }
  let(:project) { create(:project, :repository) }

  before do
    project.add_maintainer(user)
    sign_in user
  end

  describe "branches" do
    shared_examples 'compares branches' do
      it 'compares branches' do
        visit project_compare_index_path(project, from: 'master', to: 'master')

        select_using_dropdown 'from', 'feature'
        expect(find('.js-compare-from-dropdown .gl-new-dropdown-button-text')).to have_content('feature')

        select_using_dropdown 'to', 'binary-encoding'
        expect(find('.js-compare-to-dropdown .gl-new-dropdown-button-text')).to have_content('binary-encoding')

        click_button 'Compare'

        expect(page).to have_content 'Commits'
        expect(page).to have_link 'Create merge request'
      end
    end

    it "pre-populates fields" do
      visit project_compare_index_path(project, from: "master", to: "master")

      expect(find(".js-compare-from-dropdown .gl-new-dropdown-button-text")).to have_content("master")
      expect(find(".js-compare-to-dropdown .gl-new-dropdown-button-text")).to have_content("master")
    end

    it_behaves_like 'compares branches'

    context 'on a read-only instance' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it_behaves_like 'compares branches'
    end

    it 'renders additions info when click unfold diff' do
      visit project_compare_index_path(project)

      select_using_dropdown('from', RepoHelpers.sample_commit.parent_id, commit: true)
      select_using_dropdown('to', RepoHelpers.sample_commit.id, commit: true)

      click_button 'Compare'
      expect(page).to have_content 'Commits (1)'
      expect(page).to have_content "Showing 2 changed files"

      diff = first('.js-unfold')
      diff.click
      wait_for_requests

      page.within diff.query_scope do
        expect(first('.new_line').text).not_to have_content "..."
      end
    end

    context 'when project have an open merge request' do
      let!(:merge_request) do
        create(
          :merge_request,
          title: 'Feature',
          source_project: project,
          source_branch: 'feature',
          target_branch: 'master',
          author: project.users.first
        )
      end

      it 'compares branches' do
        visit project_compare_index_path(project)

        select_using_dropdown('from', 'master')
        select_using_dropdown('to', 'feature')

        click_button 'Compare'

        expect(page).to have_content 'Commits (1)'
        expect(page).to have_content 'Showing 1 changed file with 5 additions and 0 deletions'
        expect(page).to have_link 'View open merge request', href: project_merge_request_path(project, merge_request)
        expect(page).not_to have_link 'Create merge request'
      end
    end

    it "filters branches" do
      visit project_compare_index_path(project, from: "master", to: "master")

      select_using_dropdown("from", "wip")

      find(".js-compare-from-dropdown .compare-dropdown-toggle").click

      expect(find(".js-compare-from-dropdown .gl-new-dropdown-contents")).to have_selector('li.gl-new-dropdown-item', count: 1)
    end

    context 'when commit has overflow', :js do
      it 'displays warning' do
        visit project_compare_index_path(project, from: "feature", to: "master")

        allow(Commit).to receive(:max_diff_options).and_return(max_files: 3)
        allow_next_instance_of(DiffHelper) do |instance|
          allow(instance).to receive(:render_overflow_warning?).and_return(true)
        end

        click_button('Compare')

        page.within('.gl-alert') do
          expect(page).to have_text("Too many changes to show. To preserve performance only 3 of 3+ files are displayed.")
        end
      end
    end

    context "pagination" do
      before do
        stub_const("Projects::CompareController::COMMIT_DIFFS_PER_PAGE", 1)
      end

      it "shows an adjusted count for changed files on this page" do
        visit project_compare_index_path(project, from: "feature", to: "master")

        click_button('Compare')

        expect(page).to have_content("Showing 1 changed file")
      end

      it "shows commits list only on the first page" do
        visit project_compare_index_path(project, from: "feature", to: "master")
        click_button('Compare')

        expect(page).to have_content 'Commits (29)'

        # go to the second page
        within(".files .gl-pagination") do
          click_on("2")
        end

        expect(page).not_to have_content 'Commits (29)'
      end
    end
  end

  describe "tags" do
    it "compares tags" do
      visit project_compare_index_path(project, from: "master", to: "master")

      select_using_dropdown "from", "v1.0.0"
      expect(find(".js-compare-from-dropdown .gl-new-dropdown-button-text")).to have_content("v1.0.0")

      select_using_dropdown "to", "v1.1.0"
      expect(find(".js-compare-to-dropdown .gl-new-dropdown-button-text")).to have_content("v1.1.0")

      click_button "Compare"
      expect(page).to have_content "Commits"
    end
  end

  def select_using_dropdown(dropdown_type, selection, commit: false)
    wait_for_requests

    dropdown = find(".js-compare-#{dropdown_type}-dropdown")
    dropdown.find(".compare-dropdown-toggle").click
    # find input before using to wait for the inputs visibility
    dropdown.find('.dropdown-menu')
    dropdown.fill_in("Filter by Git revision", with: selection)

    wait_for_requests

    if commit
      dropdown.find('.gl-search-box-by-type-input').send_keys(:return)
    else
      # find before all to wait for the items visibility
      dropdown.find(".js-compare-#{dropdown_type}-dropdown .dropdown-item", text: selection, match: :first)
      dropdown.all(".js-compare-#{dropdown_type}-dropdown .dropdown-item", text: selection).first.click
    end
  end
end
