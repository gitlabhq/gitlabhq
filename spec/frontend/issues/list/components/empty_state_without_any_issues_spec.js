import { GlDisclosureDropdown, GlEmptyState, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import EmptyStateWithoutAnyIssues from '~/issues/list/components/empty_state_without_any_issues.vue';
import NewResourceDropdown from '~/vue_shared/components/new_resource_dropdown/new_resource_dropdown.vue';

describe('EmptyStateWithoutAnyIssues component', () => {
  let wrapper;

  const defaultProps = {
    currentTabCount: 0,
    exportCsvPathWithQuery: 'export/csv/path',
  };

  const defaultProvide = {
    canCreateProjects: false,
    fullPath: 'full/path',
    isSignedIn: true,
    newIssuePath: 'new/issue/path',
    newProjectPath: 'new/project/path',
    showNewIssueLink: false,
    signInPath: 'sign/in/path',
    groupId: '',
    isProject: false,
  };

  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findCsvImportExportDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findCreateProjectMessage = () => wrapper.findByTestId('create-project-message');
  const findGlLink = () => wrapper.findComponent(GlLink);
  const findIssuesHelpPageLink = () =>
    wrapper.findByRole('link', { name: 'Learn more about issues.' });
  const findJiraDocsLink = () =>
    wrapper.findByRole('link', { name: 'Enable the Jira integration' });
  const findNewResourceDropdown = () => wrapper.findComponent(NewResourceDropdown);
  const findNewIssueLink = () => wrapper.findByRole('link', { name: 'New issue' });
  const findNewProjectLink = () => wrapper.findByRole('link', { name: 'New project' });

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
        NewResourceDropdown: true,
      },
    });
  };

  describe('when signed in', () => {
    describe('empty state', () => {
      it('renders empty state', () => {
        mountComponent();

        expect(findGlEmptyState().props('title')).toBe(
          'Use issues to collaborate on ideas, solve problems, and plan work',
        );
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
            describe('when showNewIssueDropdown is false', () => {
              it('renders', () => {
                mountComponent({ provide: { canCreateProjects: true } });

                expect(findCreateProjectMessage().text()).toContain(
                  'Issues exist in projects. To create an issue, first create a project.',
                );
              });
            });

            describe('when showNewIssueDropdown is true', () => {
              it('renders', () => {
                mountComponent({
                  props: { showNewIssueDropdown: true },
                  provide: { canCreateProjects: true },
                });

                expect(findCreateProjectMessage().text()).toContain(
                  'Issues exist in projects. Select a project to create an issue, or create a project.',
                );
              });
            });
          });

          describe('when cannot create projects', () => {
            it('does not render', () => {
              mountComponent({ provide: { canCreateProjects: false } });

              expect(findCreateProjectMessage().exists()).toBe(false);
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
    });

    describe('Jira section', () => {
      beforeEach(() => {
        mountComponent();
      });

      it('shows Jira integration information', () => {
        const paragraphs = wrapper.findAll('p');
        expect(paragraphs.at(1).text()).toContain('Using Jira for issue tracking?');
        expect(paragraphs.at(2).text()).toMatchInterpolatedText(
          'Enable the Jira integration to view your Jira issues in GitLab.',
        );
        expect(paragraphs.at(3).text()).toContain('This feature requires a Premium plan.');
      });

      it('renders Jira integration docs link', () => {
        expect(findJiraDocsLink().attributes('href')).toBe(
          '/help/integration/jira/configure#view-jira-issues',
        );
      });
    });
  });

  describe('when signed out', () => {
    beforeEach(() => {
      mountComponent({ provide: { isSignedIn: false } });
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'Use issues to collaborate on ideas, solve problems, and plan work',
        primaryButtonText: 'Register / Sign In',
        primaryButtonLink: defaultProvide.signInPath,
      });
    });

    it('renders issues docs link', () => {
      expect(findGlLink().attributes('href')).toBe(EmptyStateWithoutAnyIssues.issuesHelpPagePath);
      expect(findGlLink().text()).toBe('Learn more about issues.');
    });
  });
});
