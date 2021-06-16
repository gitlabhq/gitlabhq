import { shallowMount } from '@vue/test-utils';

import JiraUpgradeCta from '~/integrations/edit/components/jira_upgrade_cta.vue';

describe('JiraUpgradeCta', () => {
  let wrapper;

  const contentMessage = 'Upgrade your plan to enable this feature of the Jira Integration.';

  const createComponent = (propsData) => {
    wrapper = shallowMount(JiraUpgradeCta, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the correct message for premium and lower users', () => {
    createComponent({ showPremiumMessage: true });
    expect(wrapper.text()).toContain('This is a Premium feature');
    expect(wrapper.text()).toContain(contentMessage);
  });

  it('displays the correct message for ultimate and lower users', () => {
    createComponent({ showUltimateMessage: true });
    expect(wrapper.text()).toContain('This is an Ultimate feature');
    expect(wrapper.text()).toContain(contentMessage);
  });
});
