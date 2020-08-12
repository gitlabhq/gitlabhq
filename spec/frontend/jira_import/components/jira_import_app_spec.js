import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AxiosMockAdapter from 'axios-mock-adapter';
import Vue from 'vue';
import axios from '~/lib/utils/axios_utils';
import JiraImportApp from '~/jira_import/components/jira_import_app.vue';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import JiraImportProgress from '~/jira_import/components/jira_import_progress.vue';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';
import initiateJiraImportMutation from '~/jira_import/queries/initiate_jira_import.mutation.graphql';
import getJiraUserMappingMutation from '~/jira_import/queries/get_jira_user_mapping.mutation.graphql';
import { imports, issuesPath, jiraIntegrationPath, jiraProjects, userMappings } from '../mock_data';

describe('JiraImportApp', () => {
  let axiosMock;
  let mutateSpy;
  let wrapper;

  const getFormComponent = () => wrapper.find(JiraImportForm);

  const getProgressComponent = () => wrapper.find(JiraImportProgress);

  const getSetupComponent = () => wrapper.find(JiraImportSetup);

  const getAlert = () => wrapper.find(GlAlert);

  const getLoadingIcon = () => wrapper.find(GlLoadingIcon);

  const mountComponent = ({
    isJiraConfigured = true,
    errorMessage = '',
    showAlert = false,
    isInProgress = false,
    loading = false,
    mutate = mutateSpy,
  } = {}) =>
    shallowMount(JiraImportApp, {
      propsData: {
        inProgressIllustration: 'in-progress-illustration.svg',
        isJiraConfigured,
        issuesPath,
        jiraIntegrationPath,
        projectId: '5',
        projectPath: 'gitlab-org/gitlab-test',
        setupIllustration: 'setup-illustration.svg',
      },
      data() {
        return {
          isSubmitting: false,
          userMappings,
          errorMessage,
          showAlert,
          jiraImportDetails: {
            isInProgress,
            imports,
            mostRecentImport: imports[imports.length - 1],
            projects: jiraProjects,
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

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    mutateSpy = jest.fn(() =>
      Promise.resolve({
        data: {
          jiraImportStart: { errors: [] },
          jiraImportUsers: { jiraUsers: [], errors: [] },
        },
      }),
    );
  });

  afterEach(() => {
    axiosMock.restore();
    mutateSpy.mockRestore();
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
      wrapper = mountComponent({ isInProgress: true });
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
      wrapper = mountComponent({ isInProgress: true });
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

  describe('initiating a Jira import', () => {
    it('calls the mutation with the expected arguments', () => {
      wrapper = mountComponent();

      const mutationArguments = {
        mutation: initiateJiraImportMutation,
        variables: {
          input: {
            jiraProjectKey: 'MTG',
            projectPath: 'gitlab-org/gitlab-test',
            usersMapping: [
              {
                jiraAccountId: 'aei23f98f-q23fj98qfj',
                gitlabId: 15,
              },
              {
                jiraAccountId: 'fu39y8t34w-rq3u289t3h4i',
                gitlabId: undefined,
              },
            ],
          },
        },
      };

      getFormComponent().vm.$emit('initiateJiraImport', 'MTG');

      expect(mutateSpy).toHaveBeenCalledWith(expect.objectContaining(mutationArguments));
    });

    describe('when there is an error', () => {
      beforeEach(() => {
        const mutate = jest.fn(() => Promise.reject());
        wrapper = mountComponent({ mutate });

        getFormComponent().vm.$emit('initiateJiraImport', 'MTG');
      });

      it('shows alert message with error message', async () => {
        expect(getAlert().text()).toBe('There was an error importing the Jira project.');
      });
    });
  });

  describe('alert', () => {
    it('can be dismissed', async () => {
      wrapper = mountComponent({
        errorMessage: 'There was an error importing the Jira project.',
        showAlert: true,
        selectedProject: null,
      });

      expect(getAlert().exists()).toBe(true);

      getAlert().vm.$emit('dismiss');

      await Vue.nextTick();

      expect(getAlert().exists()).toBe(false);
    });
  });

  describe('on mount GraphQL user mapping mutation', () => {
    it('is called with the expected arguments', () => {
      wrapper = mountComponent();

      const mutationArguments = {
        mutation: getJiraUserMappingMutation,
        variables: {
          input: {
            projectPath: 'gitlab-org/gitlab-test',
          },
        },
      };

      expect(mutateSpy).toHaveBeenCalledWith(expect.objectContaining(mutationArguments));
    });

    describe('when Jira is not configured', () => {
      it('is not called', () => {
        wrapper = mountComponent({ isJiraConfigured: false });

        expect(mutateSpy).not.toHaveBeenCalled();
      });
    });

    describe('when there is an error when called', () => {
      beforeEach(() => {
        const mutate = jest.fn(() => Promise.reject());
        wrapper = mountComponent({ mutate });
      });

      it('shows error message', () => {
        expect(getAlert().exists()).toBe(true);
      });
    });
  });
});
