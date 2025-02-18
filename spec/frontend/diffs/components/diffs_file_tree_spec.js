import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { Mousetrap } from '~/lib/mousetrap';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';
import { getCookie, removeCookie, setCookie } from '~/lib/utils/common_utils';
import { TREE_LIST_WIDTH_STORAGE_KEY } from '~/diffs/constants';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';

describe('DiffsFileTree', () => {
  useLocalStorageSpy();

  let wrapper;

  const createComponent = ({ visible = true } = {}) => {
    wrapper = shallowMount(DiffsFileTree, {
      propsData: {
        visible,
      },
    });
  };

  it('re-emits clickFile event', () => {
    const obj = {};
    createComponent();
    wrapper.findComponent(TreeList).vm.$emit('clickFile', obj);
    expect(wrapper.emitted('clickFile')).toStrictEqual([[obj]]);
  });

  describe('visibility', () => {
    describe('when renderDiffFiles and showTreeList are true', () => {
      beforeEach(() => {
        createComponent();
      });

      it('tree list is visible', () => {
        expect(wrapper.findComponent(TreeList).exists()).toBe(true);
      });
    });

    describe('when renderDiffFiles and showTreeList are false', () => {
      beforeEach(() => {
        createComponent({ visible: false });
      });

      it('tree list is hidden', () => {
        expect(wrapper.findComponent(TreeList).exists()).toBe(false);
      });
    });
  });

  it('toggles when "f" hotkey is pressed', async () => {
    createComponent();
    Mousetrap.trigger('f');
    await nextTick();
    expect(wrapper.emitted('toggled')).toStrictEqual([[]]);
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
});
