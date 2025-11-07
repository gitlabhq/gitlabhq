# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Related issues', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:project_b) { create(:project_empty_repo, :public) }
  let_it_be(:project_unauthorized) { create(:project_empty_repo) }
  let_it_be(:internal_project) { create(:project_empty_repo, :internal) }
  let_it_be(:private_project) { create(:project_empty_repo, :private) }
  let_it_be(:public_project) { create(:project_empty_repo, :public) }

  let_it_be(:issue_a) { create(:issue, project: project) }
  let_it_be(:issue_b) { create(:issue, project: project) }
  let_it_be(:issue_c) { create(:issue, project: project) }
  let_it_be(:issue_d) { create(:issue, project: project) }
  let_it_be(:issue_project_b_a) { create(:issue, project: project_b) }
  let_it_be(:issue_project_unauthorized_a) { create(:issue, project: project_unauthorized) }
  let_it_be(:private_issue) { create(:issue, project: private_project) }
  let_it_be(:internal_issue) { create(:issue, project: internal_project) }
  let_it_be(:internal_issue_2) { create(:issue, project: internal_project) }
  let_it_be(:internal_issue_link) { create :issue_link, source: internal_issue, target: internal_issue_2 }
  let_it_be(:public_issue) { create(:issue, project: public_project) }
  let_it_be(:public_issue_2) { create(:issue, project: public_project) }
  let_it_be(:public_issue_link) { create :issue_link, source: public_issue, target: public_issue_2 }

  before do
    stub_feature_flags(work_item_view_for_issues: true)
  end

  context 'widget visibility' do
    context 'when not logged in' do
      it 'does not show widget when internal project' do
        visit project_issue_path(internal_project, internal_issue)

        expect(page).not_to have_css('[data-testid="work-item-relationships"]')
      end

      it 'does not show widget when private project' do
        visit project_issue_path(private_project, private_issue)

        expect(page).not_to have_css('[data-testid="work-item-relationships"]')
      end

      it 'shows widget when public project' do
        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).not_to have_button 'Add'
        end
      end
    end

    context 'when logged in but not a member' do
      before do
        sign_in(user)
      end

      it 'shows widget when internal project' do
        visit project_issue_path(internal_project, internal_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).not_to have_button 'Add'
        end
      end

      it 'does not show widget when private project' do
        visit project_issue_path(private_project, private_issue)

        expect(page).not_to have_css('[data-testid="work-item-relationships"]')
      end

      it 'shows widget when public project' do
        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).not_to have_button 'Add'
        end
      end

      it 'shows widget on their own public issue' do
        issue = create :issue, project: public_project, author: user
        issue_2 = create :issue, project: public_project, author: user
        create :issue_link, source: issue, target: issue_2

        visit project_issue_path(public_project, issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).not_to have_button 'Add'
        end
      end
    end

    context 'when logged in and a guest' do
      before do
        sign_in(user)
      end

      it 'shows widget when internal project' do
        internal_project.add_guest(user)

        visit project_issue_path(internal_project, internal_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).to have_button 'Add'
        end
      end

      it 'shows widget when private project' do
        private_project.add_guest(user)

        visit project_issue_path(private_project, private_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).to have_button 'Add'
        end
      end

      it 'shows widget when public project' do
        public_project.add_guest(user)

        visit project_issue_path(public_project, public_issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).to have_button 'Add'
        end
      end

      it 'shows widget on their own public issue' do
        issue = create :issue, project: public_project, author: user
        public_project.add_guest(user)

        visit project_issue_path(public_project, issue)

        expect(page).to have_css('[data-testid="work-item-relationships"]')
        within_testid('work-item-relationships') do
          expect(page).to have_button 'Add'
        end
      end
    end
  end

  context 'when user has no permission to manage related issues' do
    let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
    let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

    before_all do
      project.add_guest(user)
    end

    before do
      sign_in(user)
    end

    context 'visiting some issue someone else created' do
      before do
        visit project_issue_path(project, issue_a)
      end

      it 'shows related issues count', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/563602' do
        within_testid('work-item-relationships') do
          expect(page).to have_css('[data-testid="crud-count"]', text: '2')
        end
      end
    end

    context 'visiting issue_b which was targeted by issue_a' do
      before do
        visit project_issue_path(project, issue_b)
      end

      it 'shows related issues count' do
        within_testid('work-item-relationships') do
          expect(page).to have_css('[data-testid="crud-count"]', text: '1')
        end
      end
    end
  end

  context 'when user has permission to manage related issues' do
    before_all do
      project.add_maintainer(user)
      project_b.add_maintainer(user)
    end

    before do
      sign_in(user)
    end

    context 'without existing related issues' do
      before do
        visit project_issue_path(project, issue_a)
      end

      it 'add related issue' do
        within_testid('work-item-relationships') do
          expect(page).to have_css('[data-testid="crud-count"]', text: '0')

          click_button 'Add'
          fill_in 'Search existing items', with: issue_b.title
          click_button issue_b.title, match: :first
          send_keys :escape # hide issue autocomplete dropdown
          within_testid('crud-form') do
            click_button 'Add'
          end

          expect(page).to have_css('[data-testid="crud-count"]', text: '1')
          expect(page).to have_link(issue_b.title)
          # Form gets hidden after submission
          expect(page).not_to have_selector('[data-testid="crud-form"]')
        end
      end

      it 'pressing enter should submit the form' do
        within_testid('work-item-relationships') do
          click_button 'Add'
          fill_in 'Search existing items', with: issue_b.title
          click_button issue_b.title, match: :first
          send_keys :enter

          expect(page).to have_css('[data-testid="crud-count"]', text: '1')
          expect(page).to have_link(issue_b.title)
          # Form gets hidden after submission
          expect(page).not_to have_selector('[data-testid="crud-form"]')
        end
      end

      it 'disallows duplicate entries' do
        within_testid('work-item-relationships') do
          click_button 'Add'
          fill_in 'Search existing items', with: issue_b.title
          click_button issue_b.title, match: :first
          send_keys issue_b.title

          expect(page).to have_text('No matches found')
        end
      end

      it 'allows us to remove pending issues' do
        # Tests against https://gitlab.com/gitlab-org/gitlab/issues/11625
        within_testid('work-item-relationships') do
          click_button 'Add'
          fill_in 'Search existing items', with: issue_b.title
          click_button issue_b.title, match: :first
          send_keys issue_c.title
          click_button issue_c.title, match: :first
          send_keys issue_d.title
          click_button issue_d.title, match: :first

          expect(page).to have_css('.gl-token-selector-token-container', count: 3)
          expect(page).to have_text(issue_b.title)
          expect(page).to have_text(issue_c.title)
          expect(page).to have_text(issue_d.title)

          click_button 'Remove', match: :first
          send_keys :escape # hide issue autocomplete dropdown

          expect(page).to have_css('.gl-token-selector-token-container', count: 2)
          expect(page).not_to have_text(issue_b.title)
          expect(page).to have_text(issue_c.title)
          expect(page).to have_text(issue_d.title)

          click_button 'Remove', match: :first
          send_keys :escape # hide issue autocomplete dropdown

          expect(page).to have_css('.gl-token-selector-token-container', count: 1)
          expect(page).not_to have_text(issue_b.title)
          expect(page).not_to have_text(issue_c.title)
          expect(page).to have_text(issue_d.title)

          click_button 'Remove', match: :first
          send_keys :escape # hide issue autocomplete dropdown

          expect(page).to have_css('.gl-token-selector-token-container', count: 0)
          expect(page).not_to have_text(issue_b.title)
          expect(page).not_to have_text(issue_c.title)
          expect(page).not_to have_text(issue_d.title)
        end
      end
    end

    context 'with existing related issues' do
      let!(:issue_link_b) { create :issue_link, source: issue_a, target: issue_b }
      let!(:issue_link_c) { create :issue_link, source: issue_a, target: issue_c }

      before do
        visit project_issue_path(project, issue_a)
      end

      it 'allows us to add and remove related issues' do
        within_testid('work-item-relationships') do
          expect(page).to have_css('[data-testid="crud-count"]', text: '2')
          expect(page).to have_link(issue_b.title)
          expect(page).to have_link(issue_c.title)
          expect(page).not_to have_link(issue_d.title)

          click_button 'Add'
          fill_in 'Search existing items', with: issue_d.title
          click_button issue_d.title, match: :first
          within_testid('crud-form') do
            click_button 'Add'
          end

          expect(page).to have_css('[data-testid="crud-count"]', text: '3')
          expect(page).to have_link(issue_b.title)
          expect(page).to have_link(issue_c.title)
          expect(page).to have_link(issue_d.title)

          click_button 'Remove', match: :first

          expect(page).to have_css('[data-testid="crud-count"]', text: '2')
          expect(page).to have_link(issue_b.title)
          expect(page).to have_link(issue_c.title)
          expect(page).not_to have_link(issue_d.title)
        end
      end

      it 'add invalid related issue' do
        within_testid('work-item-relationships') do
          click_button 'Add'
          fill_in 'Search existing items', with: '#9999999 '

          expect(page).to have_text('No matches found')
          within_testid('crud-form') do
            expect(page).to have_button('Add', disabled: true)
          end
        end
      end

      it 'cannot add unauthorized related issue' do
        within_testid('work-item-relationships') do
          click_button 'Add'
          fill_in 'Search existing items', with: issue_project_unauthorized_a.title

          expect(page).to have_text('No matches found')
        end
      end
    end
  end
end
