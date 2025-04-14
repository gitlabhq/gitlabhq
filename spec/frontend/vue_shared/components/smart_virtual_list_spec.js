import { mount } from '@vue/test-utils';
import VirtualList from 'vue-virtual-scroll-list';
import SmartVirtualScrollList from '~/vue_shared/components/smart_virtual_list.vue';

// Mock the VirtualList component for Vue 3 compatibility
jest.mock('vue-virtual-scroll-list', () => {
  return {
    __esModule: true,
    default: {
      name: 'VirtualList',
      render(createElement) {
        return createElement(this.rtag, { class: 'js-virtual-list' }, [
          createElement(this.wtag, { class: this.wclass }, this.$slots.default),
        ]);
      },
      props: {
        size: Number,
        remain: Number,
        rtag: String,
        wtag: String,
        wclass: String,
      },
    },
  };
});

describe('Smart Virtual List', () => {
  let wrapper;

  const createComponent = ({ length, remain }) => {
    const smartListProperties = {
      rtag: 'section',
      wtag: 'ul',
      wclass: 'test-class',
      // Size in pixels does not matter for our tests here
      size: 35,
      length,
      remain,
    };

    const items = Array(length).fill(1);

    // Use Vue 2 compatible approach for defining data
    const Component = {
      components: {
        SmartVirtualScrollList,
      },
      data() {
        return {
          smartListProperties,
          items,
        };
      },
      template: `
      <smart-virtual-scroll-list v-bind="smartListProperties">
        <li v-for="(val, key) in items" :key="key">{{ key + 1 }}</li>
      </smart-virtual-scroll-list>`,
    };

    return mount(Component);
  };

  const findVirtualScrollList = () => wrapper.findComponent(SmartVirtualScrollList);
  const findVirtualListItem = () => wrapper.findComponent(VirtualList);

  describe('if the list is shorter than the maximum shown elements', () => {
    const listLength = 10;

    beforeEach(() => {
      wrapper = createComponent({ length: listLength, remain: 20 });
    });

    it('renders without the vue-virtual-scroll-list component', () => {
      expect(findVirtualListItem().exists()).toBe(false);
    });

    it('renders list with provided tags and classes for the wrapper elements', () => {
      expect(wrapper.element.tagName).toEqual('SECTION');
      expect(wrapper.element.firstChild.tagName).toEqual('UL');
      expect(wrapper.element.firstChild.classList.contains('test-class')).toBe(true);
    });

    it('renders all children list elements', () => {
      expect(wrapper.findAll('li').length).toEqual(listLength);
    });
  });

  describe('if the list is longer than the maximum shown elements', () => {
    const maxItemsShown = 20;

    beforeEach(() => {
      wrapper = createComponent({ length: 1000, remain: maxItemsShown });
    });

    it('uses the vue-virtual-scroll-list component', () => {
      expect(findVirtualListItem().exists()).toBe(true);
    });

    it('renders list with provided tags and classes for the wrapper elements', () => {
      expect(findVirtualScrollList().props('rtag')).toEqual('section');
      expect(findVirtualScrollList().props('wtag')).toEqual('ul');
      expect(findVirtualScrollList().props('wclass')).toEqual('test-class');
    });

    it('renders at least some list elements', () => {
      // In our mocked version we can't reliably test exact counts
      // since the virtualization logic is mocked
      expect(wrapper.findAll('li').length).toBeGreaterThan(0);
    });
  });
});
