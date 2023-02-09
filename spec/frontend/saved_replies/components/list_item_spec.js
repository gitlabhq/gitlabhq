import { shallowMount } from '@vue/test-utils';
import ListItem from '~/saved_replies/components/list_item.vue';

let wrapper;

function createComponent(propsData = {}) {
  return shallowMount(ListItem, {
    propsData,
  });
}

describe('Saved replies list item component', () => {
  afterEach(() => {
    wrapper.destroy();
  });

  it('renders list item', async () => {
    wrapper = createComponent({ reply: { name: 'test', content: '/assign_reviewer' } });

    expect(wrapper.element).toMatchSnapshot();
  });
});
