import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import TerminalSyncStatus from '~/ide/components/terminal_sync/terminal_sync_status.vue';
import TerminalSyncStatusSafe from '~/ide/components/terminal_sync/terminal_sync_status_safe.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/terminal_sync/terminal_sync_status_safe', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    store = new Vuex.Store({
      state: {},
    });

    wrapper = shallowMount(TerminalSyncStatusSafe, {
      localVue,
      store,
    });
  };

  beforeEach(createComponent);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with terminal sync module in store', () => {
    beforeEach(() => {
      store.registerModule('terminalSync', {
        state: {},
      });
    });

    it('renders terminal sync status', () => {
      expect(wrapper.find(TerminalSyncStatus).exists()).toBe(true);
    });
  });

  describe('without terminal sync module', () => {
    it('does not render terminal sync status', () => {
      expect(wrapper.find(TerminalSyncStatus).exists()).toBe(false);
    });
  });
});
