import { mount } from '@vue/test-utils';
import OrderedLayout from '~/pages/shared/wikis/wiki_notes/components/ordered_layout.vue';

const children = `
    <template #header>
      <header></header>
    </template>
    <template #main>
      <main></main>
    </template>
    <template #footer>
      <footer></footer>
    </template>
  `;

const TestComponent = {
  components: { OrderedLayout },
  template: `
    <div>
      <ordered-layout v-bind="$attrs">
        ${children}
      </ordered-layout>
    </div>
    `,
};

describe('Ordered Layout', () => {
  let wrapper;

  const verifyOrder = () =>
    wrapper.findAll('footer,header,main').wrappers.map((x) => x.element.tagName.toLowerCase());

  const createComponent = (props = {}) => {
    wrapper = mount(TestComponent, {
      propsData: props,
    });
  };

  it.each`
    slotKeys
    ${['header', 'main', 'footer']}
    ${['header', 'footer', 'main']}
    ${['main', 'header', 'footer']}
    ${['main', 'footer', 'header']}
    ${['footer', 'header', 'main']}
    ${['footer', 'main', 'header']}
  `('should render main in the correct order', ({ slotKeys }) => {
    createComponent({ slotKeys });
    expect(verifyOrder()).toEqual(slotKeys);
  });
});
