import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, removeCookie, setCookie } from '~/lib/utils/common_utils';
import { TREE_LIST_WIDTH_STORAGE_KEY } from '~/diffs/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import store from '~/mr_notes/stores';
import * as types from '~/diffs/store/mutation_types';

describe('DiffsFileTree', () => {
  useLocalStorageSpy();

  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(DiffsFileTree, {
      store,
      propsData,
    });
  };

  it('re-emits clickFile event', () => {
    const obj = {};
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('clickFile', obj);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[obj]]);
  });

  it('sets current file on click', () => {
    const spy = jest.spyOn(store, 'commit');
    const file = { fileHash: 'foo' };
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('clickFile', file);
    expect(spy).toHaveBeenCalledWith(
      `diffs/${types.SET_CURRENT_DIFF_FILE}`,
      file.fileHash,
      undefined,
    );
  });

  describe('size', () => {
    const checkWidth = (width) => {
      expect(wrapper.element.style.width).toEqual(`${width}px`);
      expect(wrapper.findComponent(PanelResizer).props('startSize')).toEqual(width);
    };

    afterEach(() => {
      localStorage.removeItem('mr_tree_list_width');
    });

    describe('when no localStorage record is set', () => {
      beforeEach(() => {
        createComponent();
      });

      it('sets initial width when no localStorage has been set', () => {
        checkWidth(320);
      });
    });

    it('sets initial width to localStorage size', () => {
      localStorage.setItem('mr_tree_list_width', '200');
      createComponent();
      checkWidth(200);
    });

    it('updates width', async () => {
      const WIDTH = 500;
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', WIDTH);
      await nextTick();
      checkWidth(WIDTH);
    });

    it('passes down hideFileStats as true when width is less than 260', async () => {
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 200);
      await nextTick();
      expect(wrapper.findComponent(TreeList).props('hideFileStats')).toBe(true);
    });

    it('passes down hideFileStats as false when width is bigger than 260', async () => {
      createComponent();
      wrapper.findComponent(PanelResizer).vm.$emit('update:size', 300);
      await nextTick();
      expect(wrapper.findComponent(TreeList).props('hideFileStats')).toBe(false);
    });

    describe('persistence', () => {
      beforeEach(() => {
        removeCookie(TREE_LIST_WIDTH_STORAGE_KEY);
        window.localStorage.clear();
      });

      it('recovers width value from cookies', () => {
        setCookie(TREE_LIST_WIDTH_STORAGE_KEY, '250');
        createComponent();
        checkWidth(250);
      });

      it('recovers width value from local storage', () => {
        window.localStorage.setItem(TREE_LIST_WIDTH_STORAGE_KEY, '260');
        createComponent();
        checkWidth(260);
      });

      it('stores width value in cookies', async () => {
        createComponent();
        wrapper.findComponent(PanelResizer).vm.$emit('resize-end', 350);
        await nextTick();
        expect(getCookie(TREE_LIST_WIDTH_STORAGE_KEY)).toBe('350');
      });
    });
  });

  it('passes down loadedFiles table to tree list', () => {
    const loadedFiles = { foo: true };
    createComponent({ loadedFiles });
    expect(wrapper.findComponent(TreeList).props('loadedFiles')).toBe(loadedFiles);
  });
});
