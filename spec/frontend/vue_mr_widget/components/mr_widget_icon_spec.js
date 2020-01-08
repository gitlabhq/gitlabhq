import { shallowMount } from '@vue/test-utils';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

const TEST_ICON = 'commit';

describe('MrWidgetIcon', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(MrWidgetIcon, {
      propsData: {
        name: TEST_ICON,
      },
      sync: false,
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders icon and container', () => {
    expect(wrapper.is('.circle-icon-container')).toBe(true);
    expect(wrapper.find(Icon).props('name')).toEqual(TEST_ICON);
  });
});
