import { shallowMount } from '@vue/test-utils';
import { GlTabs } from '@gitlab/ui';

import PlaceholdersTabApp from '~/members/components/placeholders/app.vue';

describe('PlaceholdersTabApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PlaceholdersTabApp, {});
  };

  const findTabs = () => wrapper.findComponent(GlTabs);

  it('renders tabs', () => {
    createComponent();

    expect(findTabs().exists()).toBe(true);
  });
});
