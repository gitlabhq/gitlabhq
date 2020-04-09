import { shallowMount } from '@vue/test-utils';
import JiraImportSetup from '~/jira_import/components/jira_import_setup.vue';

describe('JiraImportSetup', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(JiraImportSetup, {
      propsData: {
        illustration: 'illustration.svg',
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays a message to the user', () => {
    const message = 'You will first need to set up Jira Integration to use this feature.';
    expect(wrapper.find('p').text()).toBe(message);
  });

  it('contains button to set up Jira integration', () => {
    expect(wrapper.find('a').text()).toBe('Set up Jira Integration');
  });
});
