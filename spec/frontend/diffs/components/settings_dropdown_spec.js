import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import diffModule from '~/diffs/store/modules';
import SettingsDropdown from '~/diffs/components/settings_dropdown.vue';
import {
  EVT_VIEW_FILE_BY_FILE,
  PARALLEL_DIFF_VIEW_TYPE,
  INLINE_DIFF_VIEW_TYPE,
} from '~/diffs/constants';
import eventHub from '~/diffs/event_hub';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Diff settings dropdown component', () => {
  let wrapper;
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

    wrapper = mount(SettingsDropdown, {
      localVue,
      store,
    });
    vm = wrapper.vm;
  }

  function getFileByFileCheckbox(vueWrapper) {
    return vueWrapper.find('[data-testid="file-by-file"]');
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
    wrapper.destroy();
  });

  describe('tree view buttons', () => {
    it('list view button dispatches setRenderTreeList with false', () => {
      createComponent();

      wrapper.find('.js-list-view').trigger('click');

      expect(actions.setRenderTreeList).toHaveBeenCalledWith(expect.anything(), false);
    });

    it('tree view button dispatches setRenderTreeList with true', () => {
      createComponent();

      wrapper.find('.js-tree-view').trigger('click');

      expect(actions.setRenderTreeList).toHaveBeenCalledWith(expect.anything(), true);
    });

    it('sets list button as selected when renderTreeList is false', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          renderTreeList: false,
        });
      });

      expect(wrapper.find('.js-list-view').classes('selected')).toBe(true);
      expect(wrapper.find('.js-tree-view').classes('selected')).toBe(false);
    });

    it('sets tree button as selected when renderTreeList is true', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          renderTreeList: true,
        });
      });

      expect(wrapper.find('.js-list-view').classes('selected')).toBe(false);
      expect(wrapper.find('.js-tree-view').classes('selected')).toBe(true);
    });
  });

  describe('compare changes', () => {
    it('sets inline button as selected', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          diffViewType: INLINE_DIFF_VIEW_TYPE,
        });
      });

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(true);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(false);
    });

    it('sets parallel button as selected', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          diffViewType: PARALLEL_DIFF_VIEW_TYPE,
        });
      });

      expect(wrapper.find('.js-inline-diff-button').classes('selected')).toBe(false);
      expect(wrapper.find('.js-parallel-diff-button').classes('selected')).toBe(true);
    });

    it('calls setInlineDiffViewType when clicking inline button', () => {
      createComponent();

      wrapper.find('.js-inline-diff-button').trigger('click');

      expect(actions.setInlineDiffViewType).toHaveBeenCalled();
    });

    it('calls setParallelDiffViewType when clicking parallel button', () => {
      createComponent();

      wrapper.find('.js-parallel-diff-button').trigger('click');

      expect(actions.setParallelDiffViewType).toHaveBeenCalled();
    });
  });

  describe('whitespace toggle', () => {
    it('does not set as checked when showWhitespace is false', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          showWhitespace: false,
        });
      });

      expect(wrapper.find('#show-whitespace').element.checked).toBe(false);
    });

    it('sets as checked when showWhitespace is true', () => {
      createComponent((store) => {
        Object.assign(store.state.diffs, {
          showWhitespace: true,
        });
      });

      expect(wrapper.find('#show-whitespace').element.checked).toBe(true);
    });

    it('calls setShowWhitespace on change', () => {
      createComponent();

      const checkbox = wrapper.find('#show-whitespace');

      checkbox.element.checked = true;
      checkbox.trigger('change');

      expect(actions.setShowWhitespace).toHaveBeenCalledWith(expect.anything(), {
        showWhitespace: true,
        pushState: true,
      });
    });
  });

  describe('file-by-file toggle', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
    });

    it.each`
      fileByFile | checked
      ${true}    | ${true}
      ${false}   | ${false}
    `(
      'sets the checkbox to { checked: $checked } if the fileByFile setting is $fileByFile',
      async ({ fileByFile, checked }) => {
        createComponent((store) => {
          Object.assign(store.state.diffs, {
            viewDiffsFileByFile: fileByFile,
          });
        });

        await vm.$nextTick();

        expect(getFileByFileCheckbox(wrapper).element.checked).toBe(checked);
      },
    );

    it.each`
      start    | emit
      ${true}  | ${false}
      ${false} | ${true}
    `(
      'when the file by file setting starts as $start, toggling the checkbox should emit an event set to $emit',
      async ({ start, emit }) => {
        createComponent((store) => {
          Object.assign(store.state.diffs, {
            viewDiffsFileByFile: start,
          });
        });

        await vm.$nextTick();

        getFileByFileCheckbox(wrapper).trigger('click');

        await vm.$nextTick();

        expect(eventHub.$emit).toHaveBeenCalledWith(EVT_VIEW_FILE_BY_FILE, { setting: emit });
      },
    );
  });
});
