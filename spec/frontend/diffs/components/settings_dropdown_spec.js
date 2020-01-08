import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import diffModule from '~/diffs/store/modules';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import { PARALLEL_DIFF_VIEW_TYPE, INLINE_DIFF_VIEW_TYPE } from '~/diffs/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Diff settiings dropdown component', () => {
  let vm;
  let actions;

  function createComponent(extendStore = () => {}) {
    const store = new Vuex.Store({
      modules: {
        diffs: {
          namespaced: true,
          actions,
          state: diffModule().state,
          getters: diffModule().getters,
        },
      },
    });

    extendStore(store);

    vm = mount(SettingsDropdown, {
      localVue,
      store,
      sync: false,
    });
  }

  beforeEach(() => {
    actions = {
      setInlineDiffViewType: jest.fn(),
      setParallelDiffViewType: jest.fn(),
      setRenderTreeList: jest.fn(),
      setShowWhitespace: jest.fn(),
    };
  });

  afterEach(() => {
    vm.destroy();
  });

  describe('tree view buttons', () => {
    it('list view button dispatches setRenderTreeList with false', () => {
      createComponent();

      vm.find('.js-list-view').trigger('click');

      expect(actions.setRenderTreeList).toHaveBeenCalledWith(expect.anything(), false, undefined);
    });

    it('tree view button dispatches setRenderTreeList with true', () => {
      createComponent();

      vm.find('.js-tree-view').trigger('click');

      expect(actions.setRenderTreeList).toHaveBeenCalledWith(expect.anything(), true, undefined);
    });

    it('sets list button as active when renderTreeList is false', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          renderTreeList: false,
        });
      });

      expect(vm.find('.js-list-view').classes('active')).toBe(true);
      expect(vm.find('.js-tree-view').classes('active')).toBe(false);
    });

    it('sets tree button as active when renderTreeList is true', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          renderTreeList: true,
        });
      });

      expect(vm.find('.js-list-view').classes('active')).toBe(false);
      expect(vm.find('.js-tree-view').classes('active')).toBe(true);
    });
  });

  describe('compare changes', () => {
    it('sets inline button as active', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          diffViewType: INLINE_DIFF_VIEW_TYPE,
        });
      });

      expect(vm.find('.js-inline-diff-button').classes('active')).toBe(true);
      expect(vm.find('.js-parallel-diff-button').classes('active')).toBe(false);
    });

    it('sets parallel button as active', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        });
      });

      expect(vm.find('.js-inline-diff-button').classes('active')).toBe(false);
      expect(vm.find('.js-parallel-diff-button').classes('active')).toBe(true);
    });

    it('calls setInlineDiffViewType when clicking inline button', () => {
      createComponent();

      vm.find('.js-inline-diff-button').trigger('click');

      expect(actions.setInlineDiffViewType).toHaveBeenCalled();
    });

    it('calls setParallelDiffViewType when clicking parallel button', () => {
      createComponent();

      vm.find('.js-parallel-diff-button').trigger('click');

      expect(actions.setParallelDiffViewType).toHaveBeenCalled();
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          showWhitespace: false,
        });
      });

      expect(vm.find('#show-whitespace').element.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      createComponent(store => {
        Object.assign(store.state.diffs, {
          showWhitespace: true,
        });
      });

      expect(vm.find('#show-whitespace').element.checked).toBe(true);
    });

    it('calls setShowWhitespace on change', () => {
      createComponent();

      const checkbox = vm.find('#show-whitespace');

      checkbox.element.checked = true;
      checkbox.trigger('change');

      expect(actions.setShowWhitespace).toHaveBeenCalledWith(
        expect.anything(),
        {
          showWhitespace: true,
          pushState: true,
        },
        undefined,
      );
    });
  });
});
