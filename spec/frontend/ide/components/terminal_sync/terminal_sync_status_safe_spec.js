import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TerminalSyncStatus from '~/ide/components/terminal_sync/terminal_sync_status.vue';
import TerminalSyncStatusSafe from '~/ide/components/terminal_sync/terminal_sync_status_safe.vue';

Vue.use(Vuex);

describe('ide/components/terminal_sync/terminal_sync_status_safe', () => {
  let store;
  let wrapper;

  const createComponent = () => {
    store = new Vuex.Store({
      state: {},
    });

    wrapper = shallowMount(TerminalSyncStatusSafe, {
      store,
    });
  };

  beforeEach(createComponent);

  describe('with terminal sync module in store', () => {
    beforeEach(() => {
      store.registerModule('terminalSync', {
        state: {},
      });
    });

    it('renders terminal sync status', () => {
      expect(wrapper.findComponent(TerminalSyncStatus).exists()).toBe(true);
    });
  });

  describe('without terminal sync module', () => {
    it('does not render terminal sync status', () => {
      expect(wrapper.findComponent(TerminalSyncStatus).exists()).toBe(false);
    });
  });
});
