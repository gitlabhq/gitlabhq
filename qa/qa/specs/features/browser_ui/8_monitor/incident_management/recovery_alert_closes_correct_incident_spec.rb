# frozen_string_literal: true

module QA
  RSpec.describe 'Monitor', product_group: :respond, quarantine: {
    type: :bug,
    issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/395512'
  } do
    describe 'Recovery alert' do
      shared_examples 'triggers recovery alert' do
        it 'only closes the correct incident', :aggregate_failures do
          Page::Project::Menu.perform(&:go_to_monitor_incidents)
          Page::Project::Monitor::Incidents::Index.perform do |index|
            # Open tab is displayed by default
            expect(index).to have_incident(title: unresolve_title),
              'Expected to see the unresolved incident in the Open tab'
            expect(index).to have_no_incident(title: resolve_title),
              'Did not expect to see the resolved incident in the Open tab'

            index.go_to_tab('Closed')
            expect(index).to have_incident(title: resolve_title),
              'Expected to see the resolved incident in the Closed tab'
            expect(index).to have_no_incident(title: unresolve_title),
              'Did not expect to see the unresolved incident in the Closed tab'
          end
        end
      end

      before do
        Flow::Login.sign_in
        project.visit!
        Flow::AlertSettings.go_to_monitor_settings
        Flow::AlertSettings.enable_create_incident
      end

      context(
        'when using HTTP endpoint integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393842'
      ) do
        include_context 'sends and resolves test alerts'

        it_behaves_like 'triggers recovery alert'
      end

      context(
        'when using Prometheus integration',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/393843'
      ) do
        include_context 'sends and resolves test alerts'

        let(:http) { false }

        it_behaves_like 'triggers recovery alert'
      end
    end
  end
end
