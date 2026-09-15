import { mount } from '@vue/test-utils';

// In Vue 3 mode, vuedraggable isn't resolved to the Vue 3 compatible version
// (it's skipped in jest.config.base.js), so we need stub it.
jest.mock('vuedraggable', () =>
  process.env.VUE_VERSION === '3'
    ? {
        name: 'DraggableStub',
        props: {
          modelValue: { type: Array, required: false, default: () => [] },
          itemKey: { type: [String, Function], required: false, default: 'id' },
        },
        template: `<ul>
          <slot name="header"></slot>
          <template v-for="(element, index) in modelValue">
            <slot name="item" :element="element" :index="index"></slot>
          </template>
          <slot name="footer"></slot>
        </ul>`,
      }
    : jest.requireActual('vuedraggable'),
);

// eslint-disable-next-line import/first
import DraggableCompat from '~/lib/utils/vue3compat/draggable_compat.vue';

describe('DraggableCompat', () => {
  let wrapper;

  const items = [
    { id: 'item-1', title: 'One' },
    { id: 'item-2', title: 'Two' },
  ];

  const createComponent = ({ template, data = {} }) => {
    wrapper = mount({
      components: { DraggableCompat },
      data() {
        return { items, showLeadingNode: false, showHeaderNode: false, ...data };
      },
      template,
    });
  };

  const findRenderedTexts = () => wrapper.findAll('li').wrappers.map((item) => item.text());

  it('renders an item per element when the v-for is the only node in the slot', () => {
    createComponent({
      template: `
        <draggable-compat :value="items" item-key="id" tag="ul">
          <li v-for="item in items" :key="item.id">{{ item.title }}</li>
        </draggable-compat>`,
    });

    expect(findRenderedTexts()).toEqual(['One', 'Two']);
  });

  it('renders an item per element when other nodes precede the v-for', () => {
    createComponent({
      template: `
        <draggable-compat :value="items" item-key="id" tag="ul">
          <li v-if="showLeadingNode" key="leading">Leading</li>
          <li v-for="item in items" :key="item.id">{{ item.title }}</li>
        </draggable-compat>`,
    });

    expect(findRenderedTexts()).toEqual(['One', 'Two']);
  });

  it('renders items from every v-for in the slot', () => {
    createComponent({
      template: `
        <draggable-compat :value="items" item-key="id" tag="ul">
          <li v-for="item in items.slice(0, 1)" :key="item.id">{{ item.title }}</li>
          <li v-for="item in items.slice(1)" :key="item.id">{{ item.title }}</li>
        </draggable-compat>`,
    });

    expect(findRenderedTexts()).toEqual(['One', 'Two']);
  });

  it('resolves items through a function itemKey', () => {
    createComponent({
      template: `
        <draggable-compat :value="items" :item-key="(item) => item.id" tag="ul">
          <li v-if="showLeadingNode" key="leading">Leading</li>
          <li v-for="item in items" :key="item.id">{{ item.title }}</li>
        </draggable-compat>`,
    });

    expect(findRenderedTexts()).toEqual(['One', 'Two']);
  });

  describe('header and footer slots', () => {
    const templateWithHeaderAndFooter = `
      <draggable-compat :value="items" item-key="id" tag="ul">
        <template #header>
          <li v-if="showHeaderNode">Header</li>
        </template>
        <li v-for="item in items" :key="item.id">{{ item.title }}</li>
        <template #footer>
          <li v-for="n in footerNodeCount" :key="'footer-' + n">Footer {{ n }}</li>
          <li v-if="!items.length">Empty</li>
          <li>Last</li>
        </template>
      </draggable-compat>`;

    it('renders them around the items, in the order they were written', () => {
      createComponent({
        template: templateWithHeaderAndFooter,
        data: { showHeaderNode: true, footerNodeCount: 2 },
      });

      expect(findRenderedTexts()).toEqual(['Header', 'One', 'Two', 'Footer 1', 'Footer 2', 'Last']);
    });

    it('renders them when there are no items at all', () => {
      createComponent({
        template: templateWithHeaderAndFooter,
        data: { items: [], footerNodeCount: 0 },
      });

      expect(findRenderedTexts()).toEqual(['Empty', 'Last']);
    });
  });
});
