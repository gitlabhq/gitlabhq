# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Compare", :js, feature_category: :source_code_management do
  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before_all do
    project.add_maintainer(user)
  end

  before do
    sign_in user
  end

  describe "compare view of branches" do
    shared_examples 'compares branches' do
      it 'compares branches' do
        visit project_compare_index_path(project, from: 'master', to: 'master')

        select_using_dropdown 'from', 'feature'
        within('.js-compare-from-dropdown') do
          expect(find_by_testid('base-dropdown-toggle')).to have_content("feature")
        end

        select_using_dropdown 'to', 'binary-encoding'
        within('.js-compare-to-dropdown') do
          expect(find_by_testid('base-dropdown-toggle')).to have_content("binary-encoding")
        end

        click_button 'Compare'

        expect(page).to have_content 'Commits on Source'
        expect(page).to have_link 'Create merge request'
      end
    end

    it "pre-populates fields" do
      visit project_compare_index_path(project, from: "master", to: "master")

      within('.js-compare-from-dropdown') do
        expect(find_by_testid('base-dropdown-toggle')).to have_content("master")
      end
      within('.js-compare-to-dropdown') do
        expect(find_by_testid('base-dropdown-toggle')).to have_content("master")
      end
    end

    it_behaves_like 'compares branches'

    context 'on a read-only instance' do
      before do
        allow(Gitlab::Database).to receive(:read_only?).and_return(true)
      end

      it_behaves_like 'compares branches'
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

        expect(page).to have_content 'Commits on Source 1'
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

    context 'when displayed with rapid_diffs' do
      let(:from) { RepoHelpers.sample_commit.parent_id }
      let(:to) { RepoHelpers.sample_commit.id }
      let(:compare) { CompareService.new(project, to).execute(project, from) }
      let(:diffs) { compare.diffs }

      before do
        visit project_compare_path(project, from: from, to: to)

        wait_for_requests
      end

      it_behaves_like 'Rapid Diffs application'
    end
  end

  describe "compare view of tags" do
    it "compares tags" do
      visit project_compare_index_path(project, from: "master", to: "master")

      select_using_dropdown "from", "v1.0.0"
      within('.js-compare-from-dropdown') do
        expect(find_by_testid('base-dropdown-toggle')).to have_content("v1.0.0")
      end

      select_using_dropdown "to", "v1.1.0"
      within('.js-compare-to-dropdown') do
        expect(find_by_testid('base-dropdown-toggle')).to have_content("v1.1.0")
      end

      click_button "Compare"
      expect(page).to have_content "Commits on Source"
    end
  end

  def select_using_dropdown(dropdown_type, selection, commit: false)
    wait_for_requests

    dropdown = find(".js-compare-#{dropdown_type}-dropdown")
    dropdown.find(".compare-dropdown-toggle").click
    # find input before using to wait for the inputs visibility
    dropdown.find('.gl-new-dropdown-panel')
    dropdown.fill_in("Filter by Git revision", with: selection)

    wait_for_requests
    sleep 0.3 # Allow Vue component to render search results

    if commit
      # wait for searching for commits to finish
      has_testid?('listbox-no-results-text')

      find_by_testid('listbox-search-input').send_keys(:return)
    else
      # find before all to wait for the items visibility
      within(".js-compare-#{dropdown_type}-dropdown") do
        all_by_testid("listbox-item-#{selection}").first.click
      end
    end
  end
end
