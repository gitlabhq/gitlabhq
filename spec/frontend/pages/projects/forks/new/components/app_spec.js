import { shallowMount } from '@vue/test-utils';
import App from '~/pages/projects/forks/new/components/app.vue';
import ForkForm from '~/pages/projects/forks/new/components/fork_form.vue';

describe('App component', () => {
  let wrapper;

  const DEFAULT_PROPS = {
    forkIllustration: 'illustrations/project-create-new-sm.svg',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(App, {
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('displays the correct svg illustration', () => {
    expect(wrapper.find('img').element.src).toBe('illustrations/project-create-new-sm.svg');
  });

  it('renders ForkForm component', () => {
    expect(wrapper.findComponent(ForkForm).exists()).toBe(true);
  });
});
