import { GlDisclosureDropdown, GlEmptyState, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import EmptyStateWithoutAnyIssues from '~/issues/list/components/empty_state_without_any_issues.vue';
import EmptyStateWithoutAnyIssuesExperiment from '~/issues/list/components/empty_state_without_any_issues_experiment.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';
import { i18n } from '~/issues/list/constants';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';

describe('EmptyStateWithoutAnyIssues component', () => {
  let wrapper;

  const defaultProps = {
    currentTabCount: 0,
    exportCsvPathWithQuery: 'export/csv/path',
  };

  const defaultProvide = {
    canCreateProjects: false,
    emptyStateSvgPath: 'empty/state/svg/path',
    fullPath: 'full/path',
    isSignedIn: true,
    jiraIntegrationPath: 'jira/integration/path',
    newIssuePath: 'new/issue/path',
    newProjectPath: 'new/project/path',
    showNewIssueLink: false,
    signInPath: 'sign/in/path',
    groupId: '',
    isProject: false,
  };

  const findSignedInEmptyStateBlock = () => wrapper.findByTestId('signed-in-empty-state-block');
  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findCsvImportExportDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findIssuesHelpPageLink = () =>
    wrapper.findByRole('link', { name: i18n.noIssuesDescription });
  const findJiraDocsLink = () =>
    wrapper.findByRole('link', { name: 'Enable the Jira integration' });
  const findNewResourceDropdown = () => wrapper.findComponent(NewResourceDropdown);
  const findNewIssueLink = () => wrapper.findByRole('link', { name: i18n.newIssueLabel });
  const findNewProjectLink = () => wrapper.findByRole('link', { name: i18n.newProjectLabel });

  const mountComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(EmptyStateWithoutAnyIssues, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        GitlabExperiment,
        NewResourceDropdown: true,
      },
    });
  };

  describe('when signed in', () => {
    describe('empty state', () => {
      it('renders empty state', () => {
        mountComponent();

        expect(findGlEmptyState().props()).toMatchObject({
          title: i18n.noIssuesTitle,
          svgPath: defaultProvide.emptyStateSvgPath,
        });
      });

      describe('description', () => {
        it('renders issues docs link', () => {
          mountComponent();

          expect(findIssuesHelpPageLink().attributes('href')).toBe(
            EmptyStateWithoutAnyIssues.issuesHelpPagePath,
          );
        });

        describe('"create a project first" description', () => {
          describe('when can create projects', () => {
            it('renders', () => {
              mountComponent({ provide: { canCreateProjects: true } });

              expect(findGlEmptyState().text()).toContain(i18n.noGroupIssuesSignedInDescription);
            });
          });

          describe('when cannot create projects', () => {
            it('does not render', () => {
              mountComponent({ provide: { canCreateProjects: false } });

              expect(findGlEmptyState().text()).not.toContain(
                i18n.noGroupIssuesSignedInDescription,
              );
            });
          });
        });
      });

      describe('actions', () => {
        describe('"New project" link', () => {
          describe('when can create projects', () => {
            it('renders', () => {
              mountComponent({ provide: { canCreateProjects: true } });

              expect(findNewProjectLink().attributes('href')).toBe(defaultProvide.newProjectPath);
            });
          });

          describe('when cannot create projects', () => {
            it('does not render', () => {
              mountComponent({ provide: { canCreateProjects: false } });

              expect(findNewProjectLink().exists()).toBe(false);
            });
          });
        });

        describe('"New issue" link', () => {
          describe('when can show new issue link', () => {
            it('renders', () => {
              mountComponent({ provide: { showNewIssueLink: true } });

              expect(findNewIssueLink().attributes('href')).toBe(defaultProvide.newIssuePath);
            });
          });

          describe('when cannot show new issue link', () => {
            it('does not render', () => {
              mountComponent({ provide: { showNewIssueLink: false } });

              expect(findNewIssueLink().exists()).toBe(false);
            });
          });
        });

        describe('CSV import/export buttons', () => {
          describe('when can show csv buttons', () => {
            it('renders', () => {
              mountComponent({ props: { showCsvButtons: true } });

              expect(findCsvImportExportDropdown().props('toggleText')).toBe('Import issues');
              expect(findCsvImportExportButtons().props()).toMatchObject({
                exportCsvPath: defaultProps.exportCsvPathWithQuery,
                issuableCount: 0,
              });
            });
          });

          describe('when cannot show csv buttons', () => {
            it('does not render', () => {
              mountComponent({ props: { showCsvButtons: false } });

              expect(findCsvImportExportDropdown().exists()).toBe(false);
              expect(findCsvImportExportButtons().exists()).toBe(false);
            });
          });
        });

        describe('new issue dropdown', () => {
          describe('when can show new issue dropdown', () => {
            it('renders', () => {
              mountComponent({ props: { showNewIssueDropdown: true } });

              expect(findNewResourceDropdown().exists()).toBe(true);
            });
          });

          describe('when cannot show new issue dropdown', () => {
            it('does not render', () => {
              mountComponent({ props: { showNewIssueDropdown: false } });

              expect(findNewResourceDropdown().exists()).toBe(false);
            });
          });
        });
      });

      describe('tracking', () => {
        const experimentTracking = { 'data-track-experiment': 'issues_mrs_empty_state' };

        const emptyStateBlockTracking = {
          'data-track-action': 'render_project_issues_empty_list_page',
          'data-track-label': 'project_issues_empty_list',
        };

        const issueHelpLinkTracking = {
          'data-track-action': 'click_learn_more_project_issues_empty_list_page',
          'data-track-label': 'learn_more_project_issues_empty_list',
        };

        const jiraDocsLinkTracking = {
          'data-track-action': 'click_jira_int_project_issues_empty_list_page',
          'data-track-label': 'jira_int_project_issues_empty_list',
        };

        it('tracks new issue link', () => {
          mountComponent({ provide: { showNewIssueLink: true } });

          expect(findNewIssueLink().attributes()).toMatchObject({
            'data-track-action': 'click_new_issue_project_issues_empty_list_page',
            'data-track-label': 'new_issue_project_issues_empty_list',
            ...experimentTracking,
          });
        });

        describe('when the isProject=true', () => {
          beforeEach(() => {
            mountComponent({ provide: { isProject: true } });
          });

          it('tracks empty state block', () => {
            expect(findSignedInEmptyStateBlock().attributes()).toMatchObject({
              ...emptyStateBlockTracking,
              ...experimentTracking,
            });
          });

          it('tracks issue help link', () => {
            expect(findIssuesHelpPageLink().attributes()).toMatchObject({
              ...issueHelpLinkTracking,
              ...experimentTracking,
            });
          });

          it('tracks Jira docs link', () => {
            expect(findJiraDocsLink().attributes()).toMatchObject({
              ...jiraDocsLinkTracking,
              ...experimentTracking,
            });
          });
        });

        describe('when the isProject=false', () => {
          beforeEach(() => {
            mountComponent();
          });

          it('does not track empty state block', () => {
            expect(findSignedInEmptyStateBlock().attributes()).not.toMatchObject({
              ...emptyStateBlockTracking,
              ...experimentTracking,
            });
          });

          it('does not track issue help link', () => {
            expect(findIssuesHelpPageLink().attributes()).not.toMatchObject({
              ...issueHelpLinkTracking,
              ...experimentTracking,
            });
          });

          it('does not track Jira docs link', () => {
            expect(findJiraDocsLink().attributes()).not.toMatchObject({
              ...jiraDocsLinkTracking,
              ...experimentTracking,
            });
          });
        });
      });
    });

    describe('Jira section', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('shows Jira integration information', () => {
        const paragraphs = wrapper.findAll('p');
        expect(paragraphs.at(1).text()).toContain(i18n.jiraIntegrationTitle);
        expect(paragraphs.at(2).text()).toMatchInterpolatedText(i18n.jiraIntegrationMessage);
        expect(paragraphs.at(3).text()).toContain(i18n.jiraIntegrationSecondaryMessage);
      });

      it('renders Jira integration docs link', () => {
        expect(findJiraDocsLink().attributes('href')).toBe(defaultProvide.jiraIntegrationPath);
      });
    });

    describe('when issues_mrs_empty_state candidate experiment', () => {
      beforeEach(() => {
        stubExperiments({ issues_mrs_empty_state: 'candidate' });
      });

      it('renders EmptyStateWithoutAnyIssuesExperiment', () => {
        mountComponent();

        expect(wrapper.findComponent(EmptyStateWithoutAnyIssuesExperiment).props()).toEqual({
          showCsvButtons: false,
          showIssuableByEmail: false,
        });
      });
    });
  });

  describe('when signed out', () => {
    beforeEach(() => {
      mountComponent({ provide: { isSignedIn: false } });
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: i18n.noIssuesTitle,
        svgPath: defaultProvide.emptyStateSvgPath,
        primaryButtonText: i18n.noIssuesSignedOutButtonText,
        primaryButtonLink: defaultProvide.signInPath,
      });
    });

    it('renders issues docs link', () => {
      expect(findGlLink().attributes('href')).toBe(EmptyStateWithoutAnyIssues.issuesHelpPagePath);
      expect(findGlLink().text()).toBe(i18n.noIssuesDescription);
    });
  });
});
