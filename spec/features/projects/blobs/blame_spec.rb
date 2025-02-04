# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'File blame', :js, feature_category: :source_code_management do
  include TreeHelper

  let_it_be(:project) { create(:project, :public, :repository) }

  let(:path) { 'CHANGELOG' }

  def visit_blob_blame(path)
    visit project_blame_path(project, tree_join('master', path))
    wait_for_all_requests
  end

  context 'as a developer' do
    let(:user) { create(:user) }
    let(:role) { :developer }

    before do
      project.add_role(user, role)
      sign_in(user)
    end

    it 'does not display lock, replace and delete buttons' do
      visit_blob_blame(path)

      expect(page).not_to have_button("Lock")
      expect(page).not_to have_button("Replace")
      expect(page).not_to have_button("Delete")
    end
  end

  it 'displays a find file button that opens the global search modal' do
    visit_blob_blame(path)

    within_testid 'blob-content-holder' do
      expect(page).to have_button _('Find file')

      click_button 'Find file'
    end

    expect(page).to have_css('.global-search-modal')
  end

  it 'displays the blame page without pagination' do
    visit_blob_blame(path)

    within_testid 'blob-content-holder' do
      expect(page).to have_css('.blame-commit')
      expect(page).not_to have_css('.gl-pagination')
      expect(page).not_to have_link _('Show full blame')
    end
  end

  context 'when blob length is over the blame range limit' do
    before do
      stub_const('Gitlab::Git::BlamePagination::PAGINATION_PER_PAGE', 2)
    end

    it 'displays two first lines of the file with pagination' do
      visit_blob_blame(path)

      within_testid 'blob-content-holder' do
        expect(page).to have_css('.blame-commit')
        expect(page).to have_css('.gl-pagination')
        expect(page).to have_link _('Show full blame')

        expect(page).to have_css('#L1')
        expect(page).not_to have_css('#L3')
        expect(find('[data-testid="kaminari-pagination-item"].active')).to have_text('1')
      end
    end

    context 'when user clicks on the next button' do
      before do
        visit_blob_blame(path)

        find_by_testid('kaminari-pagination-next').click
      end

      it 'displays next two lines of the file with pagination' do
        within_testid 'blob-content-holder' do
          expect(page).not_to have_css('#L1')
          expect(page).to have_css('#L3')
          expect(find('[data-testid="kaminari-pagination-item"].active')).to have_text('2')
        end
      end

      it 'correctly redirects to the prior blame page' do
        within_testid 'blob-content-holder' do
          find('.version-link').click

          expect(find('[data-testid="kaminari-pagination-item"].active')).to have_text('2')
        end
      end
    end

    shared_examples 'a full blame page' do
      context 'when user clicks on Show full blame button' do
        before do
          visit_blob_blame(path)
          click_link _('Show full blame')
        end

        it 'displays the blame page without pagination' do
          within_testid 'blob-content-holder' do
            expect(page).to have_css('#L1')
            expect(page).to have_css('#L667')
            expect(page).not_to have_css('.gl-pagination')
          end
        end
      end
    end

    context 'when streaming is enabled' do
      before do
        stub_const('Gitlab::Git::BlamePagination::STREAMING_PER_PAGE', 50)
      end

      it_behaves_like 'a full blame page'

      it 'shows loading text', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410499' do
        visit_blob_blame(path)
        click_link _('Show full blame')
        expect(page).to have_text('Loading full blame...')
      end
    end
  end

  context 'when blob length is over global max page limit' do
    before do
      stub_const('Gitlab::Git::BlamePagination::PAGINATION_PER_PAGE', 200)
    end

    let(:path) { 'files/markdown/ruby-style-guide.md' }

    it 'displays two hundred lines of the file with pagination' do
      visit_blob_blame(path)

      within_testid 'blob-content-holder' do
        expect(page).to have_css('.blame-commit')
        expect(page).to have_css('.gl-pagination')

        expect(page).to have_css('#L1')
        expect(page).not_to have_css('#L201')
        expect(find('[data-testid="kaminari-pagination-item"].active')).to have_text('1')
      end
    end

    context 'when user clicks on the next button' do
      before do
        visit_blob_blame(path)
      end

      it 'displays next two hundred lines of the file with pagination' do
        within_testid 'blob-content-holder' do
          find_by_testid('kaminari-pagination-next').click

          expect(page).not_to have_css('#L1')
          expect(page).to have_css('#L201')
          expect(find('[data-testid="kaminari-pagination-item"].active')).to have_text('2')
        end
      end
    end
  end
end
