import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import JiraImportApp from '~/jira_import/components/jira_import_app.vue';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import JiraImportProgress from '~/jira_import/components/jira_import_progress.vue';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';
import {
  imports,
  issuesPath,
  jiraIntegrationPath,
  jiraProjects,
  projectId,
  projectPath,
} from '../mock_data';

describe('JiraImportApp', () => {
  let wrapper;

  const setupIllustration = 'setup-illustration.svg';

  const getFormComponent = () => wrapper.findComponent(JiraImportForm);

  const getProgressComponent = () => wrapper.findComponent(JiraImportProgress);

  const getSetupComponent = () => wrapper.findComponent(JiraImportSetup);

  const getAlert = () => wrapper.findComponent(GlAlert);

  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const mountComponent = ({
    isJiraConfigured = true,
    errorMessage = '',
    showAlert = false,
    isInProgress = false,
    loading = false,
  } = {}) =>
    shallowMount(JiraImportApp, {
      propsData: {
        isJiraConfigured,
        issuesPath,
        jiraIntegrationPath,
        projectId,
        projectPath,
        setupIllustration,
      },
      data() {
        return {
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
        },
      },
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

  describe('import setup component', () => {
    beforeEach(() => {
      wrapper = mountComponent({ isJiraConfigured: false });
    });

    it('receives the illustration', () => {
      expect(getSetupComponent().props('illustration')).toBe(setupIllustration);
    });

    it('receives the path to the Jira integration page', () => {
      expect(getSetupComponent().props('jiraIntegrationPath')).toBe(jiraIntegrationPath);
    });
  });

  describe('import in progress component', () => {
    beforeEach(() => {
      wrapper = mountComponent({ isInProgress: true });
    });

    it('receives the illustration', () => {
      expect(getProgressComponent().props('illustration')).toBe(setupIllustration);
    });

    it('receives the name of the most recent import initiator', () => {
      expect(getProgressComponent().props('importInitiator')).toBe('Jane Doe');
    });

    it('receives the name of the most recent imported project', () => {
      expect(getProgressComponent().props('importProject')).toBe('MTG');
    });

    it('receives the time of the most recent import', () => {
      expect(getProgressComponent().props('importTime')).toBe('2020-04-09T16:17:18+00:00');
    });

    it('receives the path to the issues page', () => {
      expect(getProgressComponent().props('issuesPath')).toBe('gitlab-org/gitlab-test/-/issues');
    });
  });

  describe('import form component', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('receives the illustration', () => {
      expect(getFormComponent().props('issuesPath')).toBe(issuesPath);
    });

    it('receives the name of the most recent import initiator', () => {
      expect(getFormComponent().props('jiraImports')).toEqual(imports);
    });

    it('receives the name of the most recent imported project', () => {
      expect(getFormComponent().props('jiraProjects')).toEqual(jiraProjects);
    });

    it('receives the project ID', () => {
      expect(getFormComponent().props('projectId')).toBe(projectId);
    });

    it('receives the project path', () => {
      expect(getFormComponent().props('projectPath')).toBe(projectPath);
    });

    it('shows an alert when it emits an error', async () => {
      expect(getAlert().exists()).toBe(false);

      getFormComponent().vm.$emit('error', 'There was an error');

      await nextTick();

      expect(getAlert().exists()).toBe(true);
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

      await nextTick();

      expect(getAlert().exists()).toBe(false);
    });
  });
});
