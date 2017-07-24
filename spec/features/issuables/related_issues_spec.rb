require 'rails_helper'

describe 'Related issues', feature: true, js: true do
  let(:project) { create(:project_empty_repo, :public) }
  let(:project_b) { create(:project_empty_repo, :public) }
  let(:project_unauthorized) { create(:project_empty_repo, :public) }
  let(:issue_a) { create(:issue, project: project) }
  let(:issue_b) { create(:issue, project: project) }
  let(:issue_c) { create(:issue, project: project) }
  let(:issue_d) { create(:issue, project: project) }
  let(:issue_project_b_a) { create(:issue, project: project_b) }
  let(:issue_project_unauthorized_a) { create(:issue, project: project_unauthorized) }
  let(:user) { create(:user) }

  context 'when user has no permission to update related issues' do
    before do
      sign_in(user)
    end

    context 'with related_issues enabled' do
      before do
        stub_licensed_features(related_issues: true)
      end

      context 'with existing related issues' do
        let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
        let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

        context 'visiting issue_a' do
          before do
            visit project_issue_path(project, issue_a)
            wait_for_requests
          end

          it 'shows related issues count' do
            expect(find('.js-related-issues-header-issue-count')).to have_content('2')
          end

          it 'does not show add related issue badge button' do
            expect(page).not_to have_selector('.js-issue-count-badge-add-button')
          end
        end

        context 'visiting issue_b which was targeted by issue_a' do
          before do
            visit project_issue_path(project, issue_b)
            wait_for_requests
          end

          it 'shows related issues count' do
            expect(find('.js-related-issues-header-issue-count')).to have_content('1')
          end
        end
      end
    end
  end

  context 'when user has permission to update related issues' do
    before do
      project.add_master(user)
      project_b.add_master(user)
      sign_in(user)
    end

    context 'with related_issues disabled' do
      let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
      let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

      before do
        visit project_issue_path(project, issue_a)
        wait_for_requests
      end

      it 'does not show the related issues block' do
        expect(page).not_to have_selector('.js-related-issues-root')
      end
    end

    context 'with related_issues enabled' do
      before do
        stub_licensed_features(related_issues: true)
      end

      context 'without existing related issues' do
        before do
          visit project_issue_path(project, issue_a)
          wait_for_requests
        end

        it 'shows related issues count' do
          expect(find('.js-related-issues-header-issue-count')).to have_content('0')
        end

        it 'shows add related issue badge button' do
          expect(page).to have_selector('.js-issue-count-badge-add-button')
        end

        it 'add related issue' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "#{issue_b.to_reference(project)} "
          find('.js-add-issuable-form-add-button').click

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          # Form gets hidden after submission
          expect(page).not_to have_selector('.js-add-related-issues-form-area')
          # Check if related issues are present
          expect(items.count).to eq(1)
          expect(items[0].text).to eq(issue_b.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end

        it 'add cross-project related issue' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "#{issue_project_b_a.to_reference(project)} "
          find('.js-add-issuable-form-add-button').click

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(1)
          expect(items[0].text).to eq(issue_project_b_a.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end

        it 'pressing enter should submit the form' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "#{issue_project_b_a.to_reference(project)} "
          find('.js-add-issuable-form-input').native.send_key(:enter)

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(1)
          expect(items[0].text).to eq(issue_project_b_a.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('1')
        end
      end

      context 'with existing related issues' do
        let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
        let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

        before do
          visit project_issue_path(project, issue_a)
          wait_for_requests
        end

        it 'shows related issues count' do
          expect(find('.js-related-issues-header-issue-count')).to have_content('2')
        end

        it 'shows related issues' do
          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(2)
          expect(items[0].text).to eq(issue_b.title)
          expect(items[1].text).to eq(issue_c.title)
        end

        it 'allows us to remove a related issues' do
          items_before = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items_before.count).to eq(2)

          first('.js-issue-token-remove-button').click

          wait_for_requests

          items_after = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items_after.count).to eq(1)
        end

        it 'add related issue' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "##{issue_d.iid} "
          find('.js-add-issuable-form-add-button').click

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(3)
          expect(items[0].text).to eq(issue_b.title)
          expect(items[1].text).to eq(issue_c.title)
          expect(items[2].text).to eq(issue_d.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('3')
        end

        it 'add invalid related issue' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "#9999999 "
          find('.js-add-issuable-form-add-button').click

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(2)
          expect(items[0].text).to eq(issue_b.title)
          expect(items[1].text).to eq(issue_c.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('2')
        end

        it 'add unauthorized related issue' do
          find('.js-issue-count-badge-add-button').click
          find('.js-add-issuable-form-input').set "#{issue_project_unauthorized_a.to_reference(project)} "
          find('.js-add-issuable-form-add-button').click

          wait_for_requests

          items = all('.js-related-issues-token-list-item .js-issue-token-title')

          expect(items.count).to eq(2)
          expect(items[0].text).to eq(issue_b.title)
          expect(items[1].text).to eq(issue_c.title)
          expect(find('.js-related-issues-header-issue-count')).to have_content('2')
        end
      end
    end
  end
end
