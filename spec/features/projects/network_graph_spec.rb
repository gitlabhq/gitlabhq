# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Network Graph', :js, feature_category: :groups_and_projects do
  let(:user) { create :user }
  let(:project) { create :project, :repository, namespace: user.namespace }
  let(:ref_selector) { '.ref-selector' }
  let(:ref_with_hash) { 'ref-#-hash' }

  before do
    sign_in(user)

    project.repository.create_branch(ref_with_hash, 'master')

    # Stub Graph max_size to speed up test (10 commits vs. 650)
    allow(Network::Graph).to receive(:max_count).and_return(10)
  end

  shared_examples 'network graph' do
    context 'when branch is master' do
      def switch_ref_to(ref_name)
        first(ref_selector).click
        wait_for_requests

        page.within ref_selector do
          fill_in 'Search by Git revision', with: ref_name
          wait_for_requests
          find('li', text: ref_name, match: :prefer_exact).click
        end
      end

      def click_show_only_selected_branch_checkbox
        find('#filter_ref').click
      end

      before do
        visit project_network_path(project, 'master')
      end

      it 'renders project network' do
        expect(page).to have_selector ".network-graph"
        expect(page).to have_selector ref_selector, text: "master"
        page.within '.network-graph' do
          expect(page).to have_content 'master'
        end
      end

      it 'switches ref to branch' do
        switch_ref_to('feature')

        expect(page).to have_selector ref_selector, text: 'feature'
        page.within '.network-graph' do
          expect(page).to have_content 'feature'
        end
      end

      it 'switches ref to branch containing a hash' do
        switch_ref_to(ref_with_hash)

        expect(page).to have_selector ref_selector, text: ref_with_hash
      end

      it 'switches ref to tag' do
        switch_ref_to('v1.0.0')

        expect(page).to have_selector ref_selector, text: 'v1.0.0'
        page.within '.network-graph' do
          expect(page).to have_content 'v1.0.0'
        end
      end

      it 'renders by commit sha of "v1.0.0"' do
        page.within ".network-form" do
          fill_in 'extended_sha1', with: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9'
          find('button').click
        end

        expect(page).to have_selector ".network-graph"
        expect(page).to have_selector ref_selector, text: "master"
        page.within '.network-graph' do
          expect(page).to have_content 'v1.0.0'
        end
      end

      it 'filters select tag' do
        switch_ref_to('v1.0.0')

        expect(page).to have_css 'title', text: 'Graph · v1.0.0', visible: false
        page.within '.network-graph' do
          expect(page).to have_content 'Change some files'
        end

        click_show_only_selected_branch_checkbox

        page.within '.network-graph' do
          expect(page).not_to have_content 'Change some files'
        end

        click_show_only_selected_branch_checkbox

        page.within '.network-graph' do
          expect(page).to have_content 'Change some files'
        end
      end

      it 'renders error message when sha commit not exists' do
        page.within ".network-form" do
          fill_in 'extended_sha1', with: ';'
          find('button').click
        end

        expect(page).to have_selector '[data-testid="alert-danger"]', text: "Git revision ';' does not exist."
      end
    end

    it 'renders project network with test branch' do
      visit project_network_path(project, "'test'")

      page.within '.network-graph' do
        expect(page).to have_content "'test'"
      end
    end
  end

  it_behaves_like 'network graph'
end
