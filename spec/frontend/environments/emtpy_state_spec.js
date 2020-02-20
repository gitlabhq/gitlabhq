import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/environments/components/empty_state.vue';

describe('environments empty state', () => {
  let vm;

  beforeEach(() => {
    vm = shallowMount(EmptyState, {
      propsData: {
        newPath: 'foo',
        canCreateEnvironment: true,
        helpPath: 'bar',
      },
    });
  });

  afterEach(() => {
    vm.destroy();
  });

  it('renders the empty state', () => {
    expect(vm.find('.js-blank-state-title').text()).toEqual(
      "You don't have any environments right now",
    );
  });

  it('renders the new environment button', () => {
    expect(vm.find('.js-new-environment-button').attributes('href')).toEqual('foo');
  });

  describe('without permission', () => {
    beforeEach(() => {
      vm.setProps({ canCreateEnvironment: false });
    });

    it('does not render the new environment button', () => {
      expect(vm.find('.js-new-environment-button').exists()).toBe(false);
    });
  });
});
