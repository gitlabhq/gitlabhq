import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/ide/components/commit_sidebar/empty_state.vue';
import { createStore } from '~/ide/stores';

describe('IDE commit panel EmptyState component', () => {
  let wrapper;

  beforeEach(() => {
    const store = createStore();
    store.state.noChangesStateSvgPath = 'no-changes';
    wrapper = shallowMount(EmptyState, { store });
  });

  it('renders no changes text when last commit message is empty', () => {
    expect(wrapper.find('h4').text()).toBe('No changes');
  });
});
