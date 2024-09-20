# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Dashboard snippets', :js, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  it_behaves_like 'a "Your work" page with sidebar and breadcrumbs', :dashboard_snippets_path, :snippets

  it 'links to the "Explore snippets" page' do
    sign_in(user)
    visit dashboard_snippets_path

    expect(page).to have_link("Explore snippets", href: explore_snippets_path)
  end

  context 'when the project has snippets' do
    let(:project) { create(:project, :public, creator: user) }
    let!(:snippets) { create_list(:project_snippet, 2, :public, author: project.first_owner, project: project) }

    before do
      allow(Snippet).to receive(:default_per_page).and_return(1)
      sign_in(project.first_owner)
      visit dashboard_snippets_path
    end

    it_behaves_like 'paginated snippets'

    it 'shows new snippet button in header' do
      parent_element = find_by_testid('page-heading-actions')
      expect(parent_element).to have_link('New snippet')
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'when there are no project snippets' do
    let(:project) { create(:project, :public, creator: user) }

    before do
      sign_in(project.first_owner)
      visit dashboard_snippets_path
    end

    it 'shows the empty state when there are no snippets' do
      element = page.find('.gl-empty-state')

      expect(element).to have_content("Code snippets")
      expect(element.find('img')['src'])
        .to have_content('illustrations/empty-state/empty-snippets-md')
    end

    it 'shows new snippet button in main content area' do
      parent_element = page.find('.gl-empty-state')
      expect(parent_element).to have_link('New snippet')
    end

    it 'shows documentation button in main comment area' do
      parent_element = page.find('.gl-empty-state')
      expect(parent_element).to have_link('Learn more', href: help_page_path('user/snippets.md'))
    end

    it 'passes axe automated accessibility testing' do
      expect(page).to be_axe_clean.within('#content-body')
    end
  end

  context 'filtering by visibility' do
    let_it_be(:snippets) do
      [
        create(:personal_snippet, :public, author: user),
        create(:personal_snippet, :internal, author: user),
        create(:personal_snippet, :private, author: user),
        create(:personal_snippet, :public)
      ]
    end

    before do
      sign_in(user)

      visit dashboard_snippets_path
    end

    it_behaves_like 'tabs with counts' do
      let_it_be(:counts) { { all: '3', public: '1', private: '1', internal: '1' } }
    end

    it 'contains all snippets of logged user' do
      expect(page).to have_css('[data-testid="snippet-link"]', count: 3)

      expect(page).to have_content(snippets[0].title)
      expect(page).to have_content(snippets[1].title)
      expect(page).to have_content(snippets[2].title)
    end

    it 'contains all private snippets of logged user when clicking on private' do
      click_link('Private')

      expect(page).to have_css('[data-testid="snippet-link"]', count: 1)
      expect(page).to have_content(snippets[2].title)
    end

    it 'contains all internal snippets of logged user when clicking on internal' do
      click_link('Internal')

      expect(page).to have_css('[data-testid="snippet-link"]', count: 1)
      expect(page).to have_content(snippets[1].title)
    end

    it 'contains all public snippets of logged user when clicking on public' do
      click_link('Public')

      expect(page).to have_css('[data-testid="snippet-link"]', count: 1)
      expect(page).to have_content(snippets[0].title)
    end
  end

  context 'as an external user' do
    let_it_be(:user) { create(:user, :external) }

    before do
      sign_in(user)
      visit dashboard_snippets_path
    end

    context 'without snippets' do
      it 'hides new snippet button' do
        expect(page).not_to have_link('New snippet')
      end
    end

    context 'with snippets' do
      let!(:snippets) { create(:personal_snippet, author: user) }

      it 'hides new snippet button' do
        expect(page).not_to have_link('New snippet')
      end
    end
  end
end
