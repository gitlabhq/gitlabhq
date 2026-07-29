import { GlAlert, GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import JiraImportApp from '~/jira_import/components/jira_import_app.vue';
import JiraImportForm from '~/jira_import/components/jira_import_form.vue';
import JiraImportProgress from '~/jira_import/components/jira_import_progress.vue';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';
import getJiraImportDetailsQuery from '~/jira_import/queries/get_jira_import_details.query.graphql';
import { IMPORT_STATE } from '~/jira_import/utils/jira_import_utils';
import {
  getJiraImportDetailsQueryResponse,
  imports,
  issuesPath,
  jiraIntegrationPath,
  jiraProjects,
  projectPath,
} from '../mock_data';

Vue.use(VueApollo);

describe('JiraImportApp', () => {
  let wrapper;

  const setupIllustration = 'setup-illustration.svg';

  const getFormComponent = () => wrapper.findComponent(JiraImportForm);

  const getProgressComponent = () => wrapper.findComponent(JiraImportProgress);

  const getSetupComponent = () => wrapper.findComponent(JiraImportSetup);

  const getAlert = () => wrapper.findComponent(GlAlert);

  const getLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const mountComponent = async ({ isJiraConfigured = true, isInProgress = false } = {}) => {
    const jiraImportDetailsHandler = jest.fn().mockResolvedValue(
      getJiraImportDetailsQueryResponse({
        jiraImportStatus: isInProgress ? IMPORT_STATE.STARTED : IMPORT_STATE.NONE,
      }),
    );

    wrapper = shallowMount(JiraImportApp, {
      apolloProvider: createMockApollo([[getJiraImportDetailsQuery, jiraImportDetailsHandler]]),
      propsData: {
        isJiraConfigured,
        issuesPath,
        jiraIntegrationPath,
        projectPath,
        setupIllustration,
      },
    });

    await waitForPromises();
  };

  describe('when Jira integration is not configured', () => {
    beforeEach(async () => {
      await mountComponent({ isJiraConfigured: false });
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
      // Deliberately not awaited: the details query is still in flight.
      mountComponent();
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
    beforeEach(async () => {
      await mountComponent({ isInProgress: true });
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
    beforeEach(async () => {
      await mountComponent();
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
    beforeEach(async () => {
      await mountComponent({ isJiraConfigured: false });
    });

    it('receives the illustration', () => {
      expect(getSetupComponent().props('illustration')).toBe(setupIllustration);
    });

    it('receives the path to the Jira integration page', () => {
      expect(getSetupComponent().props('jiraIntegrationPath')).toBe(jiraIntegrationPath);
    });
  });

  describe('import in progress component', () => {
    beforeEach(async () => {
      await mountComponent({ isInProgress: true });
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
    beforeEach(async () => {
      await mountComponent();
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
      await mountComponent();

      getFormComponent().vm.$emit('error', 'There was an error importing the Jira project.');

      await nextTick();

      expect(getAlert().exists()).toBe(true);

      getAlert().vm.$emit('dismiss');

      await nextTick();

      expect(getAlert().exists()).toBe(false);
    });
  });
});
