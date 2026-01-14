import { shallowMount } from '@vue/test-utils';
import ExploreGroupsApp from '~/explore/groups/components/app.vue';

describe('ExploreGroupsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(ExploreGroupsApp);
  };

  it('renders', () => {
    createComponent();

    expect(wrapper.find('div').exists()).toBe(true);
  });
});
