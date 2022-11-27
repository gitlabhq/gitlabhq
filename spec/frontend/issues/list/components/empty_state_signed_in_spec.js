import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import CsvImportExportButtons from '~/issuable/components/csv_import_export_buttons.vue';
import EmptyStateSignedIn from '~/issues/list/components/empty_state_signed_in.vue';
import NewIssueDropdown from '~/issues/list/components/new_issue_dropdown.vue';
import { i18n } from '~/issues/list/constants';

describe('EmptyStateSignedIn component', () => {
  let wrapper;

  const defaultProps = {
    currentTabCount: 0,
    exportCsvPathWithQuery: 'export/csv/path',
  };

  const defaultProvide = {
    canCreateProjects: false,
    emptyStateSvgPath: 'empty/state/svg/path',
    fullPath: 'full/path',
    jiraIntegrationPath: 'jira/integration/path',
    newIssuePath: 'new/issue/path',
    newProjectPath: 'new/project/path',
    showNewIssueLink: false,
  };

  const findCsvImportExportButtons = () => wrapper.findComponent(CsvImportExportButtons);
  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findIssuesHelpPageLink = () =>
    wrapper.findByRole('link', { name: i18n.noIssuesDescription });
  const findJiraDocsLink = () =>
    wrapper.findByRole('link', { name: 'Enable the Jira integration' });
  const findNewIssueDropdown = () => wrapper.findComponent(NewIssueDropdown);
  const findNewIssueLink = () => wrapper.findByRole('link', { name: i18n.newIssueLabel });
  const findNewProjectLink = () => wrapper.findByRole('link', { name: i18n.newProjectLabel });

  const mountComponent = ({ props = {}, provide = {} } = {}) => {
    wrapper = mountExtended(EmptyStateSignedIn, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      mocks: {
        $apollo: {
          queries: {
            projects: { loading: false },
          },
        },
      },
    });
  };

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
          EmptyStateSignedIn.issuesHelpPagePath,
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

            expect(findGlEmptyState().text()).not.toContain(i18n.noGroupIssuesSignedInDescription);
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

            expect(findCsvImportExportButtons().props()).toMatchObject({
              exportCsvPath: defaultProps.exportCsvPathWithQuery,
              issuableCount: 0,
            });
          });
        });

        describe('when cannot show csv buttons', () => {
          it('does not render', () => {
            mountComponent({ props: { showCsvButtons: false } });

            expect(findCsvImportExportButtons().exists()).toBe(false);
          });
        });
      });

      describe('new issue dropdown', () => {
        describe('when can show new issue dropdown', () => {
          it('renders', () => {
            mountComponent({ props: { showNewIssueDropdown: true } });

            expect(findNewIssueDropdown().exists()).toBe(true);
          });
        });

        describe('when cannot show new issue dropdown', () => {
          it('does not render', () => {
            mountComponent({ props: { showNewIssueDropdown: false } });

            expect(findNewIssueDropdown().exists()).toBe(false);
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
});
