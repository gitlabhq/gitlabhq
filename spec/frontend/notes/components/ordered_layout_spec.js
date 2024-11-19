import { mount } from '@vue/test-utils';
import orderedLayout from '~/notes/components/ordered_layout.vue';

const children = `
    <template v-slot:header>
      <header></header>
    </template>
    <template v-slot:footer>
      <footer></footer>
    </template>
  `;

const TestComponent = {
  components: { orderedLayout },
  template: `
    <div>
      <ordered-layout v-bind="$attrs">
        ${children}
      </ordered-layout>
    </div>
    `,
};

const regularSlotOrder = ['header', 'footer'];

describe('Ordered Layout', () => {
  let wrapper;

  const verifyOrder = () =>
    wrapper
      .findAll('footer,header')
      .wrappers.map((x) => (x.element.tagName === 'FOOTER' ? 'footer' : 'header'));

  const createComponent = (props = {}) => {
    wrapper = mount(TestComponent, {
      propsData: props,
    });
  };

  describe('when slotKeys are in initial slot order', () => {
    beforeEach(() => {
      createComponent({ slotKeys: regularSlotOrder });
    });

    it('confirms order of the component is reflective of slotKeys', () => {
      expect(verifyOrder()).toEqual(regularSlotOrder);
    });
  });

  describe('when slotKeys reverse the order of the props', () => {
    const reversedSlotOrder = regularSlotOrder.reverse();

    beforeEach(() => {
      createComponent({ slotKeys: reversedSlotOrder });
    });

    it('confirms order of the component is reflective of slotKeys', () => {
      expect(verifyOrder()).toEqual(reversedSlotOrder);
    });
  });
});
