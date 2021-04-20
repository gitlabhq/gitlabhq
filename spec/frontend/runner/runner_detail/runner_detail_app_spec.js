import { shallowMount } from '@vue/test-utils';
import RunnerDetailsApp from '~/runner/runner_details/runner_details_app.vue';

const mockRunnerId = '55';

describe('RunnerDetailsApp', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = shallowMount(RunnerDetailsApp, {
      propsData: {
        runnerId: mockRunnerId,
        ...props,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the runner id', () => {
    expect(wrapper.text()).toContain('Runner #55');
  });
});
