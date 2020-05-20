import { GlAlert, GlLabel } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import IssuableListRootApp from '~/issuables_list/components/issuable_list_root_app.vue';

describe('IssuableListRootApp', () => {
  const issuesPath = 'gitlab-org/gitlab-test/-/issues';
  const label = {
    color: '#333',
    title: 'jira-import::MTG-3',
  };
  let wrapper;

  const findAlert = () => wrapper.find(GlAlert);

  const findAlertLabel = () => wrapper.find(GlAlert).find(GlLabel);

  const mountComponent = ({
    isFinishedAlertShowing = false,
    isInProgressAlertShowing = false,
    isInProgress = false,
    isFinished = false,
  } = {}) =>
    shallowMount(IssuableListRootApp, {
      propsData: {
        canEdit: true,
        isJiraConfigured: true,
        issuesPath,
        projectPath: 'gitlab-org/gitlab-test',
      },
      data() {
        return {
          isFinishedAlertShowing,
          isInProgressAlertShowing,
          jiraImport: {
            isInProgress,
            isFinished,
            label,
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

      expect(wrapper.contains(GlAlert)).toBe(false);
    });
  });

  describe('when Jira import is in progress', () => {
    it('shows an alert that tells the user a Jira import is in progress', () => {
      wrapper = mountComponent({
        isInProgressAlertShowing: true,
        isInProgress: true,
      });

      expect(findAlert().text()).toBe(
        'Import in progress. Refresh page to see newly added issues.',
      );
    });
  });

  describe('when Jira import has finished', () => {
    beforeEach(() => {
      wrapper = mountComponent({
        isFinishedAlertShowing: true,
        isFinished: true,
      });
    });

    describe('shows an alert', () => {
      it('tells the user the Jira import has finished', () => {
        expect(findAlert().text()).toBe('Issues successfully imported with the label');
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
        isInProgressAlertShowing: true,
        isInProgress: true,
      });

      expect(wrapper.contains(GlAlert)).toBe(true);

      findAlert().vm.$emit('dismiss');

      return Vue.nextTick(() => {
        expect(wrapper.contains(GlAlert)).toBe(false);
      });
    });
  });
});
