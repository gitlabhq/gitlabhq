import { GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import TerminalSyncStatus from '~/ide/components/terminal_sync/terminal_sync_status.vue';
import {
  MSG_TERMINAL_SYNC_CONNECTING,
  MSG_TERMINAL_SYNC_UPLOADING,
  MSG_TERMINAL_SYNC_RUNNING,
} from '~/ide/stores/modules/terminal_sync/messages';

const TEST_MESSAGE = 'lorem ipsum dolar sit';
const START_LOADING = 'START_LOADING';

Vue.use(Vuex);

describe('ide/components/terminal_sync/terminal_sync_status', () => {
  let moduleState;
  let store;
  let wrapper;

  const createComponent = () => {
    store = new Vuex.Store({
      modules: {
        terminalSync: {
          namespaced: true,
          state: moduleState,
          mutations: {
            [START_LOADING]: (state) => {
              state.isLoading = true;
            },
          },
        },
      },
    });

    wrapper = shallowMount(TerminalSyncStatus, {
      store,
    });
  };

  beforeEach(() => {
    moduleState = {
      isLoading: false,
      isStarted: false,
      isError: false,
      message: '',
    };
  });

  describe('when doing nothing', () => {
    it('shows nothing', () => {
      createComponent();

      expect(wrapper.find('*').exists()).toBe(false);
    });
  });

  describe.each`
    description                   | state                                       | statusMessage                   | icon
    ${'when loading'}             | ${{ isLoading: true }}                      | ${MSG_TERMINAL_SYNC_CONNECTING} | ${''}
    ${'when loading and started'} | ${{ isLoading: true, isStarted: true }}     | ${MSG_TERMINAL_SYNC_UPLOADING}  | ${''}
    ${'when error'}               | ${{ isError: true, message: TEST_MESSAGE }} | ${TEST_MESSAGE}                 | ${'warning'}
    ${'when started'}             | ${{ isStarted: true }}                      | ${MSG_TERMINAL_SYNC_RUNNING}    | ${'mobile-issue-close'}
  `('$description', ({ state, statusMessage, icon }) => {
    beforeEach(() => {
      Object.assign(moduleState, state);
      createComponent();
    });

    it('shows message', () => {
      expect(wrapper.attributes('title')).toContain(statusMessage);
    });

    if (!icon) {
      it('does not render icon', () => {
        expect(wrapper.findComponent(GlIcon).exists()).toBe(false);
      });

      it('renders loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      });
    } else {
      it('renders icon', () => {
        expect(wrapper.findComponent(GlIcon).props('name')).toEqual(icon);
      });

      it('does not render loading icon', () => {
        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
      });
    }
  });
});
