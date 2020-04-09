import { shallowMount } from '@vue/test-utils';
import JiraImportApp from '~/jira_import/components/jira_import_app.vue';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';

describe('JiraImportApp', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('set up Jira integration page', () => {
    beforeEach(() => {
      wrapper = shallowMount(JiraImportApp, {
        propsData: {
          isJiraConfigured: true,
          projectPath: 'gitlab-org/gitlab-test',
          setupIllustration: 'illustration.svg',
        },
      });
    });

    it('is shown when Jira integration is not configured', () => {
      wrapper.setProps({
        isJiraConfigured: false,
      });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(JiraImportSetup).exists()).toBe(true);
      });
    });

    it('is not shown when Jira integration is configured', () => {
      expect(wrapper.find(JiraImportSetup).exists()).toBe(false);
    });
  });
});
