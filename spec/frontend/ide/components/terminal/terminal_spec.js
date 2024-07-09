import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import Terminal from '~/ide/components/terminal/terminal.vue';
import TerminalControls from '~/ide/components/terminal/terminal_controls.vue';
import {
  STARTING,
  PENDING,
  RUNNING,
  STOPPING,
  STOPPED,
} from '~/ide/stores/modules/terminal/constants';
import GLTerminal from '~/terminal/terminal';

const TEST_TERMINAL_PATH = 'terminal/path';

Vue.use(Vuex);

jest.mock('~/terminal/terminal', () =>
  jest.fn().mockImplementation(function FakeTerminal() {
    Object.assign(this, {
      dispose: jest.fn(),
      disable: jest.fn(),
      addScrollListener: jest.fn(),
      scrollToTop: jest.fn(),
      scrollToBottom: jest.fn(),
    });
  }),
);

describe('IDE Terminal', () => {
  let wrapper;
  let state;

  const factory = (propsData) => {
    const store = new Vuex.Store({
      state,
      mutations: {
        set(prevState, newState) {
          Object.assign(prevState, newState);
        },
      },
    });

    wrapper = shallowMount(Terminal, {
      propsData: {
        status: RUNNING,
        terminalPath: TEST_TERMINAL_PATH,
        ...propsData,
      },
      store,
    });
  };

  beforeEach(() => {
    state = {
      panelResizing: false,
    };
  });

  describe('loading text', () => {
    [STARTING, PENDING].forEach((status) => {
      it(`shows when starting (${status})`, () => {
        factory({ status });

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
        expect(wrapper.find('.top-bar').text()).toBe('Starting...');
      });
    });

    it(`shows when stopping`, () => {
      factory({ status: STOPPING });

      expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find('.top-bar').text()).toBe('Stopping...');
    });

    [RUNNING, STOPPED].forEach((status) => {
      it('hides when not loading', () => {
        factory({ status });

        expect(wrapper.findComponent(GlLoadingIcon).exists()).toBe(false);
        expect(wrapper.find('.top-bar').text()).toBe('');
      });
    });
  });

  describe('refs.terminal', () => {
    it('has terminal path in data', () => {
      factory();

      expect(wrapper.vm.$refs.terminal.dataset.projectPath).toBe(TEST_TERMINAL_PATH);
    });
  });

  describe('terminal controls', () => {
    beforeEach(() => {
      factory();
      wrapper.vm.createTerminal();

      return nextTick();
    });

    it('is visible if terminal is created', () => {
      expect(wrapper.findComponent(TerminalControls).exists()).toBe(true);
    });

    it('scrolls glterminal on scroll-up', () => {
      wrapper.findComponent(TerminalControls).vm.$emit('scroll-up');

      expect(wrapper.vm.glterminal.scrollToTop).toHaveBeenCalled();
    });

    it('scrolls glterminal on scroll-down', () => {
      wrapper.findComponent(TerminalControls).vm.$emit('scroll-down');

      expect(wrapper.vm.glterminal.scrollToBottom).toHaveBeenCalled();
    });

    it('has props set', () => {
      expect(wrapper.findComponent(TerminalControls).props()).toEqual({
        canScrollUp: false,
        canScrollDown: false,
      });

      const terminalInstance = GLTerminal.mock.instances[0];
      const scrollHandler = terminalInstance.addScrollListener.mock.calls[0][0];
      scrollHandler({ canScrollUp: true, canScrollDown: true });

      return nextTick().then(() => {
        expect(wrapper.findComponent(TerminalControls).props()).toEqual({
          canScrollUp: true,
          canScrollDown: true,
        });
      });
    });
  });

  describe('refresh', () => {
    it('creates the terminal if running', () => {
      factory({ status: RUNNING, terminalPath: TEST_TERMINAL_PATH });

      wrapper.vm.refresh();

      expect(GLTerminal.mock.instances).toHaveLength(1);
    });

    it('stops the terminal if stopping', async () => {
      factory({ status: RUNNING, terminalPath: TEST_TERMINAL_PATH });

      wrapper.vm.refresh();

      const terminal = GLTerminal.mock.instances[0];
      wrapper.setProps({ status: STOPPING });
      await nextTick();

      expect(terminal.disable).toHaveBeenCalled();
    });
  });

  describe('createTerminal', () => {
    beforeEach(() => {
      factory();
      wrapper.vm.createTerminal();
    });

    it('creates the terminal', () => {
      expect(GLTerminal).toHaveBeenCalledWith(wrapper.vm.$refs.terminal);
      expect(wrapper.vm.glterminal).toBeInstanceOf(GLTerminal);
    });

    describe('scroll listener', () => {
      it('has been called', () => {
        expect(wrapper.vm.glterminal.addScrollListener).toHaveBeenCalled();
      });

      it('updates scroll data when called', () => {
        expect(wrapper.vm.canScrollUp).toBe(false);
        expect(wrapper.vm.canScrollDown).toBe(false);

        const listener = wrapper.vm.glterminal.addScrollListener.mock.calls[0][0];
        listener({ canScrollUp: true, canScrollDown: true });

        expect(wrapper.vm.canScrollUp).toBe(true);
        expect(wrapper.vm.canScrollDown).toBe(true);
      });
    });
  });

  describe('destroyTerminal', () => {
    it('calls dispose', () => {
      factory();
      wrapper.vm.createTerminal();
      const disposeSpy = wrapper.vm.glterminal.dispose;

      expect(disposeSpy).not.toHaveBeenCalled();

      wrapper.vm.destroyTerminal();

      expect(disposeSpy).toHaveBeenCalled();
      expect(wrapper.vm.glterminal).toBe(null);
    });
  });

  describe('stopTerminal', () => {
    it('calls disable', () => {
      factory();
      wrapper.vm.createTerminal();

      expect(wrapper.vm.glterminal.disable).not.toHaveBeenCalled();

      wrapper.vm.stopTerminal();

      expect(wrapper.vm.glterminal.disable).toHaveBeenCalled();
    });
  });
});
