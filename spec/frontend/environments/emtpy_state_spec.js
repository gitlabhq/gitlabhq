import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/environments/components/empty_state.vue';

describe('environments empty state', () => {
  let vm;

  beforeEach(() => {
    vm = shallowMount(EmptyState, {
      propsData: {
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
});
