import { GlAlert, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import JiraIssuesImportStatus from '~/issues/list/components/jira_issues_import_status_app.vue';

describe('JiraIssuesImportStatus', () => {
  const issuesPath = 'gitlab-org/gitlab-test/-/issues';
  const label = {
    color: '#333',
    title: 'jira-import::MTG-3',
  };
  let wrapper;

  const findAlert = () => wrapper.findComponent(GlAlert);

  const findAlertLabel = () => wrapper.findComponent(GlAlert).findComponent(GlLabel);

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

  describe('when Jira import is neither in progress nor finished', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('does not show an alert', () => {
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
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

  describe('alert', () => {
    it('is hidden when dismissed', async () => {
      wrapper = mountComponent({
        shouldShowInProgressAlert: true,
      });

      expect(wrapper.findComponent(GlAlert).exists()).toBe(true);

      findAlert().vm.$emit('dismiss');

      await nextTick();
      expect(wrapper.findComponent(GlAlert).exists()).toBe(false);
    });
  });
});
