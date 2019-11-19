import Vuex from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import smooshpack from 'smooshpack';
import Clientside from '~/ide/components/preview/clientside.vue';

jest.mock('smooshpack', () => ({
  Manager: jest.fn(),
}));

const localVue = createLocalVue();
localVue.use(Vuex);

const dummyPackageJson = () => ({
  raw: JSON.stringify({
    main: 'index.js',
  }),
});

describe('IDE clientside preview', () => {
  let wrapper;
  let store;
  const storeActions = {
    getFileData: jest.fn().mockReturnValue(Promise.resolve({})),
    getRawFileData: jest.fn().mockReturnValue(Promise.resolve('')),
  };
  const storeClientsideActions = {
    pingUsage: jest.fn().mockReturnValue(Promise.resolve({})),
  };

  const waitForCalls = () => new Promise(setImmediate);

  const createComponent = ({ state, getters } = {}) => {
    store = new Vuex.Store({
      state: {
        entries: {},
        links: {},
        ...state,
      },
      getters: {
        packageJson: () => '',
        currentProject: () => ({
          visibility: 'public',
        }),
        ...getters,
      },
      actions: storeActions,
      modules: {
        clientside: {
          namespaced: true,
          actions: storeClientsideActions,
        },
      },
    });

    wrapper = shallowMount(Clientside, {
      sync: false,
      store,
      localVue,
    });
  };

  beforeAll(() => {
    jest.useFakeTimers();
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('without main entry', () => {
    it('creates sandpack manager', () => {
      createComponent();
      expect(smooshpack.Manager).not.toHaveBeenCalled();
    });
  });
  describe('with main entry', () => {
    beforeEach(() => {
      createComponent({ getters: { packageJson: dummyPackageJson } });

      return waitForCalls();
    });

    it('creates sandpack manager', () => {
      expect(smooshpack.Manager).toHaveBeenCalledWith(
        '#ide-preview',
        {
          files: {},
          entry: '/index.js',
          showOpenInCodeSandbox: true,
        },
        {
          fileResolver: {
            isFile: expect.any(Function),
            readFile: expect.any(Function),
          },
        },
      );
    });

    it('pings usage', () => {
      expect(storeClientsideActions.pingUsage).toHaveBeenCalledTimes(1);
    });
  });

  describe('computed', () => {
    describe('normalizedEntries', () => {
      it('returns flattened list of blobs with content', () => {
        createComponent({
          state: {
            entries: {
              'index.js': { type: 'blob', raw: 'test' },
              'index2.js': { type: 'blob', content: 'content' },
              tree: { type: 'tree' },
              empty: { type: 'blob' },
            },
          },
        });

        expect(wrapper.vm.normalizedEntries).toEqual({
          '/index.js': {
            code: 'test',
          },
          '/index2.js': {
            code: 'content',
          },
        });
      });
    });

    describe('mainEntry', () => {
      it('returns false when package.json is empty', () => {
        createComponent();
        expect(wrapper.vm.mainEntry).toBe(false);
      });

      it('returns main key from package.json', () => {
        createComponent({ getters: { packageJson: dummyPackageJson } });
        expect(wrapper.vm.mainEntry).toBe('index.js');
      });
    });

    describe('showPreview', () => {
      it('returns false if no mainEntry', () => {
        createComponent();
        expect(wrapper.vm.showPreview).toBe(false);
      });

      it('returns false if loading and mainEntry exists', () => {
        createComponent({ getters: { packageJson: dummyPackageJson } });
        wrapper.setData({ loading: true });

        expect(wrapper.vm.showPreview).toBe(false);
      });

      it('returns true if not loading and mainEntry exists', () => {
        createComponent({ getters: { packageJson: dummyPackageJson } });
        wrapper.setData({ loading: false });

        expect(wrapper.vm.showPreview).toBe(true);
      });
    });

    describe('showEmptyState', () => {
      it('returns true if no mainEntry exists', () => {
        createComponent();
        wrapper.setData({ loading: false });
        expect(wrapper.vm.showEmptyState).toBe(true);
      });

      it('returns false if loading', () => {
        createComponent();
        wrapper.setData({ loading: true });

        expect(wrapper.vm.showEmptyState).toBe(false);
      });

      it('returns false if not loading and mainEntry exists', () => {
        createComponent({ getters: { packageJson: dummyPackageJson } });
        wrapper.setData({ loading: false });

        expect(wrapper.vm.showEmptyState).toBe(false);
      });
    });

    describe('showOpenInCodeSandbox', () => {
      it('returns true when visibility is public', () => {
        createComponent({ getters: { currentProject: () => ({ visibility: 'public' }) } });

        expect(wrapper.vm.showOpenInCodeSandbox).toBe(true);
      });

      it('returns false when visibility is private', () => {
        createComponent({ getters: { currentProject: () => ({ visibility: 'private' }) } });

        expect(wrapper.vm.showOpenInCodeSandbox).toBe(false);
      });
    });

    describe('sandboxOpts', () => {
      beforeEach(() => {
        createComponent({
          state: {
            entries: {
              'index.js': { type: 'blob', raw: 'test' },
              'package.json': dummyPackageJson(),
            },
          },
          getters: {
            packageJson: dummyPackageJson,
          },
        });
      });

      it('returns sandbox options', () => {
        expect(wrapper.vm.sandboxOpts).toEqual({
          files: {
            '/index.js': {
              code: 'test',
            },
            '/package.json': {
              code: '{"main":"index.js"}',
            },
          },
          entry: '/index.js',
          showOpenInCodeSandbox: true,
        });
      });
    });
  });

  describe('methods', () => {
    describe('loadFileContent', () => {
      beforeEach(() => {
        createComponent();
        return wrapper.vm.loadFileContent('package.json');
      });

      it('calls getFileData', () => {
        expect(storeActions.getFileData).toHaveBeenCalledWith(
          expect.any(Object),
          {
            path: 'package.json',
            makeFileActive: false,
          },
          undefined, // vuex callback
        );
      });

      it('calls getRawFileData', () => {
        expect(storeActions.getRawFileData).toHaveBeenCalledWith(
          expect.any(Object),
          {
            path: 'package.json',
          },
          undefined, // vuex callback
        );
      });
    });

    describe('update', () => {
      beforeEach(() => {
        createComponent();
        wrapper.setData({ sandpackReady: true });
      });

      it('initializes manager if manager is empty', () => {
        createComponent({ getters: { packageJson: dummyPackageJson } });
        wrapper.setData({ sandpackReady: true });
        wrapper.vm.update();

        jest.advanceTimersByTime(250);

        return waitForCalls().then(() => {
          expect(smooshpack.Manager).toHaveBeenCalled();
        });
      });

      it('calls updatePreview', () => {
        wrapper.setData({
          manager: {
            listener: jest.fn(),
            updatePreview: jest.fn(),
          },
        });
        wrapper.vm.update();

        jest.advanceTimersByTime(250);
        expect(wrapper.vm.manager.updatePreview).toHaveBeenCalledWith(wrapper.vm.sandboxOpts);
      });
    });
  });

  describe('template', () => {
    it('renders ide-preview element when showPreview is true', () => {
      createComponent({ getters: { packageJson: dummyPackageJson } });
      wrapper.setData({ loading: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find('#ide-preview').exists()).toBe(true);
      });
    });

    it('renders empty state', () => {
      createComponent();
      wrapper.setData({ loading: false });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.text()).toContain(
          'Preview your web application using Web IDE client-side evaluation.',
        );
      });
    });

    it('renders loading icon', () => {
      createComponent();
      wrapper.setData({ loading: true });

      return wrapper.vm.$nextTick(() => {
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });
    });
  });
});
