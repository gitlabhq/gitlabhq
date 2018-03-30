require 'spec_helper'

describe 'Milestones on EE' do
  let(:user) { create(:user) }
  let(:project) { create(:project, name: 'test', namespace: user.namespace) }
  let(:milestone) { create(:milestone, project: project, start_date: Date.today, due_date: 7.days.from_now) }

  before do
    login_as(user)
  end

  def visit_milestone
    visit project_milestone_path(project, milestone)
  end

  def close_issue(issue)
    Issues::CloseService.new(issue.project, user, {}).execute(issue)
  end

  context 'burndown charts' do
    let(:milestone) do
      create(:milestone,
             project: project,
             start_date: Date.yesterday,
             due_date: Date.tomorrow)
    end

    context 'with the burndown chart feature available' do
      let(:issue_params) { { project: project, assignees: [user], author: user, milestone: milestone } }

      before do
        stub_licensed_features(burndown_charts: true)
      end

      it 'shows a burndown chart' do
        visit_milestone

        within('#content-body') do
          expect(page).to have_selector('.burndown-chart')
        end
      end

      context 'when a closed issue do not have closed events' do
        it 'shows warning' do
          close_issue(create(:issue, issue_params))
          close_issue(create(:issue, issue_params))

          # Legacy issue: No closed events being created
          create(:closed_issue, issue_params)

          visit_milestone

          expect(page).to have_selector('#data-warning', count: 1)
          expect(page.find('#data-warning').text).to include("Some issues can’t be shown in the burndown chart")
          expect(page).to have_selector('.burndown-chart')
        end
      end

      context 'when all closed issues do not have closed events' do
        it 'shows warning and hides burndown' do
          create(:closed_issue, issue_params)
          create(:closed_issue, issue_params)

          visit_milestone

          expect(page).to have_selector('#data-warning', count: 1)
          expect(page.find('#data-warning').text).to include("The burndown chart can’t be shown")
          expect(page).not_to have_selector('.burndown-chart')
        end
      end

      context 'data is accurate' do
        it 'does not show warning' do
          create(:issue, issue_params)
          close_issue(create(:issue, issue_params))

          visit_milestone

          expect(page).not_to have_selector('#data-warning')
          expect(page).to have_selector('.burndown-chart')
        end
      end

      context 'with due & start date not set' do
        let(:milestone_without_dates) { create(:milestone, project: project) }

        it 'shows a mention to fill in dates' do
          visit project_milestone_path(project, milestone_without_dates)

          within('#content-body') do
            expect(page).to have_link('Add start and due date')
          end
        end
      end
    end

    shared_examples 'burndown charts disabled' do
      it 'has a link to upgrade to Bronze when checking the namespace plan' do
        # Not using `stub_application_setting` because the method is prepended in
        # `EE::ApplicationSetting` which breaks when using `any_instance`
        # https://gitlab.com/gitlab-org/gitlab-ce/issues/33587
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:should_check_namespace_plan?) { true }

        visit_milestone

        within('#content-body') do
          expect(page).not_to have_selector('.burndown-chart')
        end
      end

      it 'has a link to upgrade to starter on premise' do
        allow(Gitlab::CurrentSettings.current_application_settings)
          .to receive(:should_check_namespace_plan?) { false }

        visit_milestone

        within('#content-body') do
          expect(page).not_to have_selector('.burndown-chart')
        end
      end
    end

    context 'with the burndown chart feature disabled' do
      before do
        stub_licensed_features(burndown_charts: false)
      end

      include_examples 'burndown charts disabled'
    end

    context 'with the issuable weights feature disabled' do
      before do
        stub_licensed_features(issue_weights: false)
      end

      include_examples 'burndown charts disabled'
    end
  end

  context 'milestone summary' do
    it 'shows the total weight when sum is greater than zero' do
      create(:issue, project: project, milestone: milestone, weight: 3)
      create(:issue, project: project, milestone: milestone, weight: 1)

      visit_milestone

      within '.milestone-sidebar' do
        expect(page).to have_content 'Total issue weight 4'
      end
    end

    it 'hides the total weight when sum is equal to zero' do
      create(:issue, project: project, milestone: milestone, weight: nil)
      create(:issue, project: project, milestone: milestone, weight: nil)

      visit_milestone

      within '.milestone-sidebar' do
        expect(page).to have_content 'Total issue weight None'
      end
    end
  end
end
