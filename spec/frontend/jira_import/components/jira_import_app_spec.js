import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import JiraImportApp from '~/jira_import/components/jira_import_app.vue';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import JiraImportProgress from '~/jira_import/components/jira_import_progress.vue';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';
import initiateJiraImportMutation from '~/jira_import/queries/initiate_jira_import.mutation.graphql';
import { IMPORT_STATE } from '~/jira_import/utils';

const mountComponent = ({
  isJiraConfigured = true,
  errorMessage = '',
  selectedProject = 'MTG',
  showAlert = false,
  status = IMPORT_STATE.NONE,
  loading = false,
  mutate = jest.fn(() => Promise.resolve()),
  mountType,
} = {}) => {
  const mountFunction = mountType === 'mount' ? mount : shallowMount;

  return mountFunction(JiraImportApp, {
    propsData: {
      isJiraConfigured,
      inProgressIllustration: 'in-progress-illustration.svg',
      issuesPath: 'gitlab-org/gitlab-test/-/issues',
      jiraIntegrationPath: 'gitlab-org/gitlab-test/-/services/jira/edit',
      projectPath: 'gitlab-org/gitlab-test',
      setupIllustration: 'setup-illustration.svg',
    },
    data() {
      return {
        errorMessage,
        showAlert,
        selectedProject,
        jiraImportDetails: {
          projects: [
            { text: 'My Jira Project (MJP)', value: 'MJP' },
            { text: 'My Second Jira Project (MSJP)', value: 'MSJP' },
            { text: 'Migrate to GitLab (MTG)', value: 'MTG' },
          ],
          status,
          imports: [
            {
              jiraProjectKey: 'MTG',
              scheduledAt: '2020-04-08T10:11:12+00:00',
              scheduledBy: {
                name: 'John Doe',
              },
            },
            {
              jiraProjectKey: 'MSJP',
              scheduledAt: '2020-04-09T13:14:15+00:00',
              scheduledBy: {
                name: 'Jimmy Doe',
              },
            },
            {
              jiraProjectKey: 'MTG',
              scheduledAt: '2020-04-09T16:17:18+00:00',
              scheduledBy: {
                name: 'Jane Doe',
              },
            },
          ],
        },
      };
    },
    mocks: {
      $apollo: {
        loading,
        mutate,
      },
    },
  });
};

describe('JiraImportApp', () => {
  let wrapper;

  const getFormComponent = () => wrapper.find(JiraImportForm);

  const getProgressComponent = () => wrapper.find(JiraImportProgress);

  const getSetupComponent = () => wrapper.find(JiraImportSetup);

  const getAlert = () => wrapper.find(GlAlert);

  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when Jira integration is not configured', () => {
    beforeEach(() => {
      wrapper = mountComponent({ isJiraConfigured: false });
    });

    it('shows the "Set up Jira integration" screen', () => {
      expect(getSetupComponent().exists()).toBe(true);
    });

    it('does not show loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('does not show the "Import in progress" screen', () => {
      expect(getProgressComponent().exists()).toBe(false);
    });

    it('does not show the "Import Jira project" form', () => {
      expect(getFormComponent().exists()).toBe(false);
    });
  });

  describe('when Jira integration is configured but data is being fetched', () => {
    beforeEach(() => {
      wrapper = mountComponent({ loading: true });
    });

    it('does not show the "Set up Jira integration" screen', () => {
      expect(getSetupComponent().exists()).toBe(false);
    });

    it('shows loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(true);
    });

    it('does not show the "Import in progress" screen', () => {
      expect(getProgressComponent().exists()).toBe(false);
    });

    it('does not show the "Import Jira project" form', () => {
      expect(getFormComponent().exists()).toBe(false);
    });
  });

  describe('when Jira integration is configured but import is in progress', () => {
    beforeEach(() => {
      wrapper = mountComponent({ status: IMPORT_STATE.SCHEDULED });
    });

    it('does not show the "Set up Jira integration" screen', () => {
      expect(getSetupComponent().exists()).toBe(false);
    });

    it('does not show loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('shows the "Import in progress" screen', () => {
      expect(getProgressComponent().exists()).toBe(true);
    });

    it('does not show the "Import Jira project" form', () => {
      expect(getFormComponent().exists()).toBe(false);
    });
  });

  describe('when Jira integration is configured and there is no import in progress', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('does not show the "Set up Jira integration" screen', () => {
      expect(getSetupComponent().exists()).toBe(false);
    });

    it('does not show loading icon', () => {
      expect(getLoadingIcon().exists()).toBe(false);
    });

    it('does not show the Import in progress" screen', () => {
      expect(getProgressComponent().exists()).toBe(false);
    });

    it('shows the "Import Jira project" form', () => {
      expect(getFormComponent().exists()).toBe(true);
    });
  });

  describe('import in progress screen', () => {
    beforeEach(() => {
      wrapper = mountComponent({ status: IMPORT_STATE.SCHEDULED });
    });

    it('shows the illustration', () => {
      expect(getProgressComponent().props('illustration')).toBe('in-progress-illustration.svg');
    });

    it('shows the name of the most recent import initiator', () => {
      expect(getProgressComponent().props('importInitiator')).toBe('Jane Doe');
    });

    it('shows the name of the most recent imported project', () => {
      expect(getProgressComponent().props('importProject')).toBe('MTG');
    });

    it('shows the time of the most recent import', () => {
      expect(getProgressComponent().props('importTime')).toBe('2020-04-09T16:17:18+00:00');
    });

    it('has the path to the issues page', () => {
      expect(getProgressComponent().props('issuesPath')).toBe('gitlab-org/gitlab-test/-/issues');
    });
  });

  describe('jira import form screen', () => {
    describe('when selected project has been imported before', () => {
      it('shows jira-import::MTG-3 label since project MTG has been imported 2 time before', () => {
        wrapper = mountComponent();

        expect(getFormComponent().props('importLabel')).toBe('jira-import::MTG-3');
      });

      it('shows warning alert to explain project MTG has been imported 2 times before', () => {
        wrapper = mountComponent({ mountType: 'mount' });

        expect(getAlert().text()).toBe(
          'You have imported from this project 2 times before. Each new import will create duplicate issues.',
        );
      });
    });

    describe('when selected project has not been imported before', () => {
      beforeEach(() => {
        wrapper = mountComponent({ selectedProject: 'MJP' });
      });

      it('shows jira-import::MJP-1 label since project MJP has not been imported before', () => {
        expect(getFormComponent().props('importLabel')).toBe('jira-import::MJP-1');
      });

      it('does not show warning alert since project MJP has not been imported before', () => {
        expect(getAlert().exists()).toBe(false);
      });
    });
  });

  describe('initiating a Jira import', () => {
    it('calls the mutation with the expected arguments', () => {
      const mutate = jest.fn(() => Promise.resolve());

      wrapper = mountComponent({ mutate });

      const mutationArguments = {
        mutation: initiateJiraImportMutation,
        variables: {
          input: {
            jiraProjectKey: 'MTG',
            projectPath: 'gitlab-org/gitlab-test',
          },
        },
      };

      getFormComponent().vm.$emit('initiateJiraImport', 'MTG');

      expect(mutate).toHaveBeenCalledWith(expect.objectContaining(mutationArguments));
    });

    it('shows alert message with error message on error', () => {
      const mutate = jest.fn(() => Promise.reject());

      wrapper = mountComponent({ mutate });

      getFormComponent().vm.$emit('initiateJiraImport', 'MTG');

      // One tick doesn't update the dom to the desired state so we have two ticks here
      return Vue.nextTick()
        .then(Vue.nextTick)
        .then(() => {
          expect(getAlert().text()).toBe('There was an error importing the Jira project.');
        });
    });
  });

  it('can dismiss alert message', () => {
    wrapper = mountComponent({
      errorMessage: 'There was an error importing the Jira project.',
      showAlert: true,
      selectedProject: null,
    });

    expect(getAlert().exists()).toBe(true);

    getAlert().vm.$emit('dismiss');

    return Vue.nextTick().then(() => {
      expect(getAlert().exists()).toBe(false);
    });
  });
});
