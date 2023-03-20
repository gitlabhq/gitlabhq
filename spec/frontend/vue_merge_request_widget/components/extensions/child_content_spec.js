import { shallowMount } from '@vue/test-utils';
import ChildContent from '~/vue_merge_request_widget/components/extensions/child_content.vue';

let wrapper;
const mockData = () => ({
  header: 'Test header',
  text: 'Test content',
  icon: {
    name: 'error',
  },
});

function factory(propsData) {
  wrapper = shallowMount(ChildContent, {
    propsData: {
      ...propsData,
      widgetLabel: 'Test',
    },
  });
}

describe('MR widget extension child content', () => {
  it('renders child components', () => {
    factory({
      data: {
        ...mockData(),
        children: [mockData()],
      },
      level: 2,
    });

    expect(wrapper.find('[data-testid="child-content"]').exists()).toBe(true);
    expect(wrapper.find('[data-testid="child-content"]').props('level')).toBe(3);
  });
});
