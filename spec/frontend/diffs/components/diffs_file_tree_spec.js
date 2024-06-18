import { nextTick } from 'vue';
import { shallowMount } from '@vue/test-utils';
import { Mousetrap } from '~/lib/mousetrap';
import DiffsFileTree from '~/diffs/components/diffs_file_tree.vue';
import TreeList from '~/diffs/components/tree_list.vue';
import PanelResizer from '~/vue_shared/components/panel_resizer.vue';

describe('DiffsFileTree', () => {
  let wrapper;

  const createComponent = ({ visible = true } = {}) => {
    wrapper = shallowMount(DiffsFileTree, {
      propsData: {
        visible,
      },
    });
  };

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
  });
});
