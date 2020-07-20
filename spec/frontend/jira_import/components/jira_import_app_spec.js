import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
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
    selectedProject = 'MTG',
    showAlert = false,
    isInProgress = false,
    loading = false,
    mutate = mutateSpy,
    mountFunction = shallowMount,
  } = {}) =>
    mountFunction(JiraImportApp, {
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
          selectedProject,
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

  describe('jira import form screen', () => {
    describe('when selected project has been imported before', () => {
      it('shows jira-import::MTG-3 label since project MTG has been imported 2 time before', () => {
        wrapper = mountComponent();

        expect(getFormComponent().props('importLabel')).toBe('jira-import::MTG-3');
      });

      it('shows warning alert to explain project MTG has been imported 2 times before', () => {
        wrapper = mountComponent({ mountFunction: mount });

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

  describe('alert', () => {
    it('can be dismissed', () => {
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

  describe('on mount', () => {
    it('makes a GraphQL mutation call to get user mappings', () => {
      wrapper = mountComponent();

      const mutationArguments = {
        mutation: getJiraUserMappingMutation,
        variables: {
          input: {
            projectPath: 'gitlab-org/gitlab-test',
            startAt: 1,
          },
        },
      };

      expect(mutateSpy).toHaveBeenCalledWith(expect.objectContaining(mutationArguments));
    });

    it('does not make a GraphQL mutation call to get user mappings when Jira is not configured', () => {
      wrapper = mountComponent({ isJiraConfigured: false });

      expect(mutateSpy).not.toHaveBeenCalled();
    });

    it('shows error message when there is an error with the GraphQL mutation call', () => {
      const mutate = jest.fn(() => Promise.reject());

      wrapper = mountComponent({ mutate });

      expect(getAlert().exists()).toBe(true);
    });
  });
});
