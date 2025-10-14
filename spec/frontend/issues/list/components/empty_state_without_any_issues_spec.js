import { GlDisclosureDropdown, GlEmptyState } from '@gitlab/ui';
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
  const findJiraDocsLink = () => wrapper.findByRole('link', { name: 'See integration options' });
  const findNewResourceDropdown = () => wrapper.findComponent(NewResourceDropdown);
  const findCreateIssueLink = () => wrapper.findByRole('link', { name: 'Create issue' });
  const findNewProjectLink = () => wrapper.findByRole('link', { name: 'New project' });

  const mountComponent = ({ props = {}, provide = {}, slots = {} } = {}) => {
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
      slots: {
        ...slots,
      },
    });
  };

  describe('when signed in', () => {
    describe('empty state', () => {
      it('renders empty state', () => {
        mountComponent();

        expect(findGlEmptyState().props('title')).toBe(
          'Track bugs, plan features, and organize your work with issues',
        );
        expect(findGlEmptyState().props('description')).toBe(
          'Use issues (also known as tickets or stories on other platforms) to collaborate on ideas, solve problems, and plan your project.',
        );
      });

      describe('actions', () => {
        describe('"New project" link', () => {
          describe('when can create projects and not in project context', () => {
            it('renders', () => {
              mountComponent({ provide: { canCreateProjects: true, isProject: false } });

              expect(findNewProjectLink().attributes('href')).toBe(defaultProvide.newProjectPath);
            });
          });

          describe('when can create projects but in project context', () => {
            it('does not render', () => {
              mountComponent({ provide: { canCreateProjects: true, isProject: true } });

              expect(findNewProjectLink().exists()).toBe(false);
            });
          });

          describe('when cannot create projects', () => {
            it('does not render', () => {
              mountComponent({ provide: { canCreateProjects: false } });

              expect(findNewProjectLink().exists()).toBe(false);
            });
          });
        });

        describe('"Create issue" link', () => {
          describe('when can show new issue link', () => {
            it('renders', () => {
              mountComponent({ provide: { showNewIssueLink: true } });

              expect(findCreateIssueLink().attributes('href')).toBe(defaultProvide.newIssuePath);
            });
          });

          describe('when cannot show new issue link', () => {
            it('does not render', () => {
              mountComponent({ provide: { showNewIssueLink: false } });

              expect(findCreateIssueLink().exists()).toBe(false);
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

          it('does not render the default buttons when overriden using slot', () => {
            mountComponent({
              props: { showCsvButtons: true },
              slots: { 'import-export-buttons': '<button></button>' },
            });

            expect(findCsvImportExportDropdown().exists()).toBe(false);
            expect(findCsvImportExportButtons().exists()).toBe(false);
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
      });

      it('renders Jira integration docs link', () => {
        expect(findJiraDocsLink().attributes('href')).toBe('/help/integration/jira/_index');
      });
    });
  });

  describe('when signed out', () => {
    beforeEach(() => {
      mountComponent({ provide: { isSignedIn: false } });
    });

    it('renders empty state', () => {
      expect(findGlEmptyState().props()).toMatchObject({
        title: 'Track bugs, plan features, and organize your work with issues',
        primaryButtonText: 'Register / Sign In',
        primaryButtonLink: defaultProvide.signInPath,
      });
    });
  });
});
