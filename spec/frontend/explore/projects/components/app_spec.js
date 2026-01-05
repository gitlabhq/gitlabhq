import { shallowMount } from '@vue/test-utils';
import ExploreProjectsApp from '~/explore/projects/components/app.vue';

describe('ExploreProjectsApp', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(ExploreProjectsApp);
  };

  it('renders', () => {
    createComponent();

    expect(wrapper.find('div').exists()).toBe(true);
  });
});
