import { GlIcon } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';

const TEST_ICON = 'commit';

describe('MrWidgetIcon', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(MrWidgetIcon, {
      propsData: {
        name: TEST_ICON,
      },
    });
  });

  it('renders icon and container', () => {
    expect(wrapper.element.className).toContain('circle-icon-container');
    expect(wrapper.findComponent(GlIcon).props('name')).toEqual(TEST_ICON);
  });
});
