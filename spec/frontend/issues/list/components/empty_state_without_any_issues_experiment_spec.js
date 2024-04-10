import { mountExtended } from 'helpers/vue_test_utils_helper';
import IssuableByEmail from '~/issuable/components/issuable_by_email.vue';
import EmptyStateWithoutAnyIssuesExperiment from '~/issues/list/components/empty_state_without_any_issues_experiment.vue';

describe('EmptyStateWithoutAnyIssuesExperiment component', () => {
  let wrapper;

  const defaultProps = {
    showCsvButtons: true,
    showIssuableByEmail: true,
  };

  const defaultProvide = {
    newIssuePath: 'new/issue/path',
    showNewIssueLink: true,
    showImportButton: true,
    canEdit: true,
    projectImportJiraPath: 'project/import/jira/path',
  };

  const findCreateAnIssueVideo = () => wrapper.findByTestId('create-an-issue-iframe-video');
  const findNewIssueButton = () => wrapper.findByTestId('empty-state-new-issue-btn');
  const findIssuableByEmail = () => wrapper.findComponent(IssuableByEmail);
  const findCsvImportButton = () => wrapper.findByTestId('empty-state-import-csv-btn');
  const findImportFromJiraButton = () => wrapper.findByTestId('empty-state-import-jira-btn');
  const findLearnMoreLink = () => wrapper.findByTestId('empty-state-learn-more-link');
  const findJiraIntLink = () => wrapper.findByTestId('empty-state-jira-int-link');

  const mountComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(EmptyStateWithoutAnyIssuesExperiment, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
    });
  };

  it('renders empty state', () => {
    mountComponent();

    expect(findCreateAnIssueVideo().exists()).toBe(true);

    expect(wrapper.find('h1').text()).toBe(
      'Use issues to collaborate on ideas, solve problems, and plan work',
    );

    const text = wrapper.text();

    expect(text).toContain(
      'With issues you can discuss the implementation of an idea, track tasks and work status, elaborate on code implementations, and accept feature proposals, questions, support requests, or bug reports.',
    );

    expect(text).toContain('Learn more about issues');
    expect(text).toContain('Read our documentation');
    expect(text).toContain('Enable Jira integration');
    expect(text).toContain('This feature is only available on paid plans.');
  });

  describe('actions', () => {
    describe('"New issue" button', () => {
      describe('when can show the button', () => {
        it('renders', () => {
          mountComponent();

          const newIssueButton = findNewIssueButton();

          expect(newIssueButton.attributes('href')).toBe(defaultProvide.newIssuePath);
          expect(newIssueButton.props('variant')).toBe('confirm');
          expect(newIssueButton.text()).toBe('Create a new issue');
        });
      });

      describe('when cannot show the button', () => {
        it('does not render', () => {
          mountComponent({ provide: { showNewIssueLink: false } });

          expect(findNewIssueButton().exists()).toBe(false);
        });
      });
    });

    describe('"Email a new issue" button', () => {
      describe('when can show the button', () => {
        it('renders', () => {
          mountComponent();

          const newIssueButton = findIssuableByEmail();

          expect(newIssueButton.props('variant')).toBe('default');
          expect(newIssueButton.text()).toBe('Email a new issue');
        });
      });

      describe('when cannot show the button', () => {
        it('does not render', () => {
          mountComponent({ props: { showIssuableByEmail: false } });

          expect(findIssuableByEmail().exists()).toBe(false);
        });
      });
    });

    describe('Import buttons', () => {
      describe('when can show csv buttons', () => {
        describe('when can show import buttons', () => {
          describe('when cannot edit', () => {
            it('renders import CSV button and does not render from Jira button', () => {
              mountComponent({ provide: { canEdit: false } });

              const csvImportButton = findCsvImportButton();

              expect(csvImportButton.exists()).toBe(true);
              expect(csvImportButton.text()).toBe('Import CSV');

              expect(findImportFromJiraButton().exists()).toBe(false);
            });
          });

          describe('when can edit', () => {
            it('renders import from Jira button', () => {
              mountComponent();

              const importFromJiraButton = findImportFromJiraButton();

              expect(importFromJiraButton.exists()).toBe(true);
              expect(importFromJiraButton.text()).toBe('Import from Jira');

              expect(importFromJiraButton.attributes('href')).toBe(
                defaultProvide.projectImportJiraPath,
              );

              expect(findCsvImportButton().exists()).toBe(true);
            });
          });
        });

        describe('when cannot show import buttons', () => {
          it('does not render import buttons', () => {
            mountComponent({ provide: { showImportButton: false } });

            expect(findCsvImportButton().exists()).toBe(false);
            expect(findImportFromJiraButton().exists()).toBe(false);
          });
        });
      });

      describe('when cannot show csv buttons', () => {
        it('does not render import buttons', () => {
          mountComponent({ props: { showCsvButtons: false } });

          expect(findCsvImportButton().exists()).toBe(false);
          expect(findImportFromJiraButton().exists()).toBe(false);
        });
      });
    });
  });

  describe('tracking', () => {
    const experimentTracking = { 'data-track-experiment': 'issues_mrs_empty_state' };

    const newIssueButtonTracking = {
      'data-track-action': 'click_new_issue_project_issues_empty_list_page',
      'data-track-label': 'new_issue_project_issues_empty_list',
    };

    const issuableByEmailTracking = {
      'data-track-action': 'click_email_issue_project_issues_empty_list_page',
      'data-track-label': 'email_issue_project_issues_empty_list',
    };

    const importCsvTracking = {
      'data-track-action': 'click_import_csv_project_issues_empty_list_page',
      'data-track-label': 'import_csv_project_issues_empty_list',
    };

    const importJiraTracking = {
      'data-track-action': 'click_import_jira_project_issues_empty_list_page',
      'data-track-label': 'import_jira_project_issues_empty_list',
    };

    const learnMoreLinkTracking = {
      'data-track-action': 'click_learn_more_project_issues_empty_list_page',
      'data-track-label': 'learn_more_project_issues_empty_list',
    };

    const jiraIntLinkTracking = {
      'data-track-action': 'click_jira_int_project_issues_empty_list_page',
      'data-track-label': 'jira_int_project_issues_empty_list',
    };

    beforeEach(() => {
      mountComponent();
    });

    it('tracks new issue button', () => {
      expect(findNewIssueButton().attributes()).toMatchObject({
        ...newIssueButtonTracking,
        ...experimentTracking,
      });
    });

    it('tracks IssuableByEmail', () => {
      expect(findIssuableByEmail().attributes()).toMatchObject({
        ...issuableByEmailTracking,
        ...experimentTracking,
      });
    });

    it('tracks import CSV button', () => {
      expect(findCsvImportButton().attributes()).toMatchObject({
        ...importCsvTracking,
        ...experimentTracking,
      });
    });

    it('tracks import Jira button', () => {
      expect(findImportFromJiraButton().attributes()).toMatchObject({
        ...importJiraTracking,
        ...experimentTracking,
      });
    });

    it('tracks learn more link', () => {
      expect(findLearnMoreLink().attributes()).toMatchObject({
        ...learnMoreLinkTracking,
        ...experimentTracking,
      });
    });

    it('tracks Jira integration link', () => {
      expect(findJiraIntLink().attributes()).toMatchObject({
        ...jiraIntLinkTracking,
        ...experimentTracking,
      });
    });
  });
});
