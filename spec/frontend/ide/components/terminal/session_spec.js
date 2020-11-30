import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import Vuex from 'vuex';
import TerminalSession from '~/ide/components/terminal/session.vue';
import Terminal from '~/ide/components/terminal/terminal.vue';
import {
  STARTING,
  PENDING,
  RUNNING,
  STOPPING,
  STOPPED,
} from '~/ide/stores/modules/terminal/constants';

const TEST_TERMINAL_PATH = 'terminal/path';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('IDE TerminalSession', () => {
  let wrapper;
  let actions;
  let state;

  const factory = (options = {}) => {
    const store = new Vuex.Store({
      modules: {
        terminal: {
          namespaced: true,
          actions,
          state,
        },
      },
    });

    wrapper = shallowMount(TerminalSession, {
      localVue,
      store,
      ...options,
    });
  };

  const findButton = () => wrapper.find(GlButton);

  beforeEach(() => {
    state = {
      session: { status: RUNNING, terminalPath: TEST_TERMINAL_PATH },
    };
    actions = {
      restartSession: jest.fn(),
      stopSession: jest.fn(),
    };
  });

  it('is empty if session is falsey', () => {
    state.session = null;
    factory();

    expect(wrapper.html()).toBe('');
  });

  it('shows terminal', () => {
    factory();

    expect(wrapper.find(Terminal).props()).toEqual({
      terminalPath: TEST_TERMINAL_PATH,
      status: RUNNING,
    });
  });

  [STARTING, PENDING, RUNNING].forEach(status => {
    it(`show stop button when status is ${status}`, () => {
      state.session = { status };
      factory();

      const button = findButton();
      button.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(button.text()).toEqual('Stop Terminal');
        expect(actions.stopSession).toHaveBeenCalled();
      });
    });
  });

  [STOPPING, STOPPED].forEach(status => {
    it(`show stop button when status is ${status}`, () => {
      state.session = { status };
      factory();

      const button = findButton();
      button.vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(button.text()).toEqual('Restart Terminal');
        expect(actions.restartSession).toHaveBeenCalled();
      });
    });
  });
});
