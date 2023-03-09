import { shallowMount } from '@vue/test-utils';
import SuccessMessage from '~/ide/components/commit_sidebar/success_message.vue';
import { createStore } from '~/ide/stores';

describe('IDE commit panel successful commit state', () => {
  let wrapper;

  beforeEach(() => {
    const store = createStore();
    store.state.committedStateSvgPath = 'committed-state';
    store.state.lastCommitMsg = 'testing commit message';
    wrapper = shallowMount(SuccessMessage, { store });
  });

  it('renders last commit message when it exists', () => {
    expect(wrapper.text()).toContain('testing commit message');
  });
});
