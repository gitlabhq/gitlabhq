import { shallowMount } from '@vue/test-utils';
import App from '~/work_items/components/app.vue';

describe('Work Items Application', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(App, {
      stubs: {
        'router-view': true,
      },
    });
  };

  it('renders a component', () => {
    createComponent();

    expect(wrapper.exists()).toBe(true);
  });
});
