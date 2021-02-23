import { GlAlert, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import JiraIssuesImportStatus from '~/issues_list/components/jira_issues_import_status_app.vue';

describe('JiraIssuesImportStatus', () => {
  const issuesPath = 'gitlab-org/gitlab-test/-/issues';
  const label = {
    color: '#333',
    title: 'jira-import::MTG-3',
  };
  let wrapper;

  const findAlert = () => wrapper.find(GlAlert);

  const findAlertLabel = () => wrapper.find(GlAlert).find(GlLabel);

  const mountComponent = ({
    shouldShowFinishedAlert = false,
    shouldShowInProgressAlert = false,
  } = {}) =>
    shallowMount(JiraIssuesImportStatus, {
      propsData: {
        canEdit: true,
        isJiraConfigured: true,
        issuesPath,
        projectPath: 'gitlab-org/gitlab-test',
      },
      data() {
        return {
          jiraImport: {
            importedIssuesCount: 1,
            label,
            shouldShowFinishedAlert,
            shouldShowInProgressAlert,
          },
        };
      },
    });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when Jira import is not in progress', () => {
    it('does not show an alert', () => {
      wrapper = mountComponent();

      expect(wrapper.find(GlAlert).exists()).toBe(false);
    });
  });

  describe('when Jira import is in progress', () => {
    it('shows an alert that tells the user a Jira import is in progress', () => {
      wrapper = mountComponent({
        shouldShowInProgressAlert: true,
      });

      expect(findAlert().text()).toBe(
        'Import in progress. Refresh page to see newly added issues.',
      );
    });
  });

  describe('when Jira import has finished', () => {
    beforeEach(() => {
      wrapper = mountComponent({
        shouldShowFinishedAlert: true,
      });
    });

    describe('shows an alert', () => {
      it('tells the user the Jira import has finished', () => {
        expect(findAlert().text()).toBe('1 issue successfully imported with the label');
      });

      it('contains the label title associated with the Jira import', () => {
        const alertLabelTitle = findAlertLabel().props('title');

        expect(alertLabelTitle).toBe(label.title);
      });

      it('contains the correct label color', () => {
        const alertLabelTitle = findAlertLabel().props('backgroundColor');

        expect(alertLabelTitle).toBe(label.color);
      });

      it('contains a link within the label', () => {
        const alertLabelTarget = findAlertLabel().props('target');

        expect(alertLabelTarget).toBe(
          `${issuesPath}?label_name[]=${encodeURIComponent(label.title)}`,
        );
      });
    });
  });

  describe('alert message', () => {
    it('is hidden when dismissed', () => {
      wrapper = mountComponent({
        shouldShowInProgressAlert: true,
      });

      expect(wrapper.find(GlAlert).exists()).toBe(true);

      findAlert().vm.$emit('dismiss');

      return Vue.nextTick(() => {
        expect(wrapper.find(GlAlert).exists()).toBe(false);
      });
    });
  });
});
