import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
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
  showAlert = true,
  status = IMPORT_STATE.NONE,
  loading = false,
  mutate = jest.fn(() => Promise.resolve()),
} = {}) =>
  shallowMount(JiraImportApp, {
    propsData: {
      isJiraConfigured,
      inProgressIllustration: 'in-progress-illustration.svg',
      issuesPath: 'gitlab-org/gitlab-test/-/issues',
      jiraProjects: [
        ['My Jira Project', 'MJP'],
        ['My Second Jira Project', 'MSJP'],
        ['Migrate to GitLab', 'MTG'],
      ],
      projectPath: 'gitlab-org/gitlab-test',
      setupIllustration: 'setup-illustration.svg',
    },
    data() {
      return {
        errorMessage,
        showAlert,
        jiraImportDetails: {
          status,
          import: {
            jiraProjectKey: 'MTG',
            scheduledAt: '2020-04-08T12:17:25+00:00',
            scheduledBy: {
              name: 'Jane Doe',
            },
          },
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
    });

    expect(getAlert().exists()).toBe(true);

    getAlert().vm.$emit('dismiss');

    return Vue.nextTick().then(() => {
      expect(getAlert().exists()).toBe(false);
    });
  });
});
