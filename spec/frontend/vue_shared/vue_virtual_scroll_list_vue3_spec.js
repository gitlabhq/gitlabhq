import { mount } from '@vue/test-utils';
import { defineComponent, h } from 'vue';
import VirtualList from 'vue-virtual-scroll-list';

const isVue3 = process.env.VUE_VERSION === '3';
const describeVue3 = isVue3 ? describe : describe.skip;

const ITEM_SIZE = 20;
const VISIBLE_COUNT = 5;
const TOTAL_ITEMS = 100;

// eslint-disable-next-line vue/one-component-per-file
const ItemComponent = defineComponent({
  props: {
    index: { type: Number, required: true },
  },
  render() {
    return h('div', { class: 'item', style: { height: `${ITEM_SIZE}px` } }, `item${this.index}`);
  },
});

function createItems(count) {
  return Array.from({ length: count }, (_, i) => i);
}

function createWrapper(propsData = {}, items = createItems(TOTAL_ITEMS)) {
  // eslint-disable-next-line vue/one-component-per-file
  const WrapperComponent = defineComponent({
    components: { VirtualList },
    props: {
      items: { type: Array, required: false, default: () => items },
      virtualListProps: { type: Object, required: false, default: () => ({}) },
    },
    render() {
      return h(
        VirtualList,
        {
          size: ITEM_SIZE,
          remain: VISIBLE_COUNT,
          ...this.virtualListProps,
        },
        {
          default: () => this.items.map((i) => h(ItemComponent, { key: i, index: i })),
        },
      );
    },
  });

  return mount(WrapperComponent, {
    propsData: {
      virtualListProps: propsData,
    },
  });
}

describeVue3('vue_virtual_scroll_list_vue3', () => {
  let wrapper;

  describe('rendering', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders root element with correct tag', () => {
      const root = wrapper.find('[style*="overflow-y"]');
      expect(root.exists()).toBe(true);
      expect(root.element.tagName.toLowerCase()).toBe('div');
    });

    it('renders wrapper element with role="group"', () => {
      const group = wrapper.find('[role="group"]');
      expect(group.exists()).toBe(true);
      expect(group.element.tagName.toLowerCase()).toBe('div');
    });

    it('sets root element height based on size * remain', () => {
      const root = wrapper.find('[style*="overflow-y"]');
      expect(root.element.style.height).toBe(`${ITEM_SIZE * VISIBLE_COUNT}px`);
    });

    it('renders only a subset of items (keeps = remain + remain)', () => {
      const items = wrapper.findAll('.item');
      const keeps = VISIBLE_COUNT + VISIBLE_COUNT;
      expect(items).toHaveLength(keeps);
    });

    it('renders item content correctly', () => {
      const items = wrapper.findAll('.item');
      expect(items.at(0).text()).toBe('item0');
      expect(items.at(1).text()).toBe('item1');
    });
  });

  describe('with fewer items than keeps', () => {
    it('renders all items when total < keeps', () => {
      const smallCount = 3;
      wrapper = createWrapper({}, createItems(smallCount));
      const items = wrapper.findAll('.item');
      expect(items).toHaveLength(smallCount);
    });

    it('sets no padding when total < keeps', () => {
      wrapper = createWrapper({}, createItems(3));
      const group = wrapper.find('[role="group"]');
      expect(group.element.style.paddingTop).toBe('0px');
      expect(group.element.style.paddingBottom).toBe('0px');
    });
  });

  describe('custom tags and classes', () => {
    it('uses custom rtag for root element', () => {
      wrapper = createWrapper({ rtag: 'section' });
      const root = wrapper.find('section[style*="overflow-y"]');
      expect(root.exists()).toBe(true);
    });

    it('uses custom wtag for wrapper element', () => {
      wrapper = createWrapper({ wtag: 'ul' });
      const group = wrapper.find('ul[role="group"]');
      expect(group.exists()).toBe(true);
    });

    it('applies wclass to wrapper element', () => {
      wrapper = createWrapper({ wclass: 'my-wrapper' });
      const group = wrapper.find('[role="group"]');
      expect(group.classes()).toContain('my-wrapper');
    });
  });

  describe('bench prop', () => {
    it('renders remain + bench items when bench is provided', () => {
      const bench = 3;
      wrapper = createWrapper({ bench });
      const items = wrapper.findAll('.item');
      expect(items).toHaveLength(VISIBLE_COUNT + bench);
    });
  });

  describe('padding', () => {
    it('sets padding-bottom on wrapper when items exceed keeps', () => {
      wrapper = createWrapper();
      const group = wrapper.find('[role="group"]');
      expect(group.element.style.paddingTop).toBe('0px');
      const paddingBottom = parseInt(group.element.style.paddingBottom, 10);
      expect(paddingBottom).toBeGreaterThan(0);
    });
  });

  describe('scrollelement', () => {
    it('renders without root scroll container when scrollelement is provided', () => {
      const el = document.createElement('div');
      wrapper = createWrapper({ scrollelement: el });
      const root = wrapper.find('[style*="overflow-y"]');
      expect(root.exists()).toBe(false);

      const group = wrapper.find('[role="group"]');
      expect(group.exists()).toBe(true);
    });
  });

  describe('empty list', () => {
    it('renders empty wrapper when no items provided', () => {
      wrapper = createWrapper({}, []);
      const group = wrapper.find('[role="group"]');
      expect(group.exists()).toBe(true);
      expect(wrapper.findAll('.item')).toHaveLength(0);
    });
  });

  describe('overflow-y style', () => {
    it('sets overflow-y to auto when size >= remain', () => {
      wrapper = createWrapper({ size: ITEM_SIZE, remain: VISIBLE_COUNT });
      const root = wrapper.find('[style*="overflow-y"]');
      expect(root.element.style.overflowY).toBe('auto');
    });

    it('sets overflow-y to initial when size < remain', () => {
      wrapper = createWrapper({ size: 1, remain: 10 });
      const root = wrapper.find('[style*="overflow-y"]');
      expect(root.element.style.overflowY).toBe('initial');
    });
  });
});
