import { mount } from '@vue/test-utils';
import ExperimentBadge from '~/vue_shared/components/badges/experiment_badge.vue';

describe('Experiment badge component', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mount(ExperimentBadge, {
      propsData: { ...props },
    });
  };

  it('renders the badge', () => {
    createWrapper();

    expect(wrapper.element).toMatchSnapshot();
  });
});
