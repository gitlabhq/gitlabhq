import { GlDrawer } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemDisplaySettingsDrawer from '~/work_items/list/components/work_item_display_settings_drawer.vue';

const MOCK_WRAPPER_HEIGHT = '99px';

jest.mock('~/lib/utils/dom_utils', () => ({
  getContentWrapperHeight: () => MOCK_WRAPPER_HEIGHT,
}));

describe('WorkItemDisplaySettingsDrawer', () => {
  let wrapper;

  const findDrawer = () => wrapper.findComponent(GlDrawer);

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMountExtended(WorkItemDisplaySettingsDrawer, {
      propsData: {
        open: false,
        ...props,
      },
      slots,
    });
  };

  it('renders the drawer closed by default', () => {
    createComponent();

    expect(findDrawer().props()).toMatchObject({
      open: false,
      headerHeight: MOCK_WRAPPER_HEIGHT,
    });
  });

  it('passes the open prop through to GlDrawer', () => {
    createComponent({ props: { open: true } });

    expect(findDrawer().props('open')).toBe(true);
  });

  it('emits close when GlDrawer emits close', () => {
    createComponent({ props: { open: true } });

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('renders slot content in place of the placeholder', () => {
    createComponent({
      slots: { default: '<div data-testid="custom-body">custom</div>' },
    });

    expect(wrapper.findByTestId('custom-body').exists()).toBe(true);
  });
});
