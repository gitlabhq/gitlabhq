import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CollapsibleSection from '~/merge_request_dashboard/components/collapsible_section.vue';

describe('Merge request dashboard collapsible section', () => {
  let wrapper;

  function createComponent(count = 3) {
    wrapper = shallowMountExtended(CollapsibleSection, {
      slots: {
        default: 'content',
      },
      propsData: {
        title: 'Approved',
        count,
      },
    });
  }

  it('renders section', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('collapses content when count is 0', () => {
    createComponent(0);

    expect(wrapper.findByTestId('section-content').exists()).toBe(false);
  });

  it('expands collapsed content', async () => {
    createComponent(1);

    wrapper.findByTestId('section-toggle-button').vm.$emit('click');

    await nextTick();

    expect(wrapper.findByTestId('section-content').exists()).toBe(false);

    wrapper.findByTestId('section-toggle-button').vm.$emit('click');

    await nextTick();

    expect(wrapper.findByTestId('section-content').exists()).toBe(true);
    expect(wrapper.findByTestId('section-content').text()).toContain('content');
  });
});
