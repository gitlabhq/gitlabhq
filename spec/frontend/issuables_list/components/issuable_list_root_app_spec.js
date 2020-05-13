import { GlAlert } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import IssuableListRootApp from '~/issuables_list/components/issuable_list_root_app.vue';

const mountComponent = ({
  canEdit = true,
  isAlertShowing = true,
  isInProgress = false,
  isJiraConfigured = true,
} = {}) =>
  shallowMount(IssuableListRootApp, {
    propsData: {
      canEdit,
      isJiraConfigured,
      projectPath: 'gitlab-org/gitlab-test',
    },
    data() {
      return {
        isAlertShowing,
        jiraImport: {
          isInProgress,
        },
      };
    },
  });

describe('IssuableListRootApp', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when Jira import is in progress', () => {
    it('shows an alert that tells the user a Jira import is in progress', () => {
      wrapper = mountComponent({
        isInProgress: true,
      });

      expect(wrapper.find(GlAlert).text()).toBe(
        'Import in progress. Refresh page to see newly added issues.',
      );
    });
  });

  describe('when Jira import is not in progress', () => {
    it('does not show an alert', () => {
      wrapper = mountComponent();

      expect(wrapper.contains(GlAlert)).toBe(false);
    });
  });

  describe('alert message', () => {
    it('is hidden when dismissed', () => {
      wrapper = mountComponent({
        isInProgress: true,
      });

      expect(wrapper.contains(GlAlert)).toBe(true);

      wrapper.find(GlAlert).vm.$emit('dismiss');

      return Vue.nextTick(() => {
        expect(wrapper.contains(GlAlert)).toBe(false);
      });
    });
  });
});
