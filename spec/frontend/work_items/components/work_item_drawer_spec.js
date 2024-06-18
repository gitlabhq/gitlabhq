import { GlDrawer, GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import WorkItemDrawer from '~/work_items/components/work_item_drawer.vue';
import WorkItemDetail from '~/work_items/components/work_item_detail.vue';

describe('WorkItemDrawer', () => {
  let wrapper;

  const mockListener = jest.fn();

  const findGlDrawer = () => wrapper.findComponent(GlDrawer);
  const findWorkItem = () => wrapper.findComponent(WorkItemDetail);

  const createComponent = ({ open = false } = {}) => {
    wrapper = shallowMount(WorkItemDrawer, {
      propsData: {
        activeItem: {
          iid: '1',
          webUrl: 'test',
        },
        open,
      },
      listeners: {
        customEvent: mockListener,
      },
    });
  };

  it('passes correct `open` prop to GlDrawer', () => {
    createComponent();

    expect(findGlDrawer().props('open')).toBe(false);
  });

  it('displays correct URL in link', () => {
    createComponent();

    expect(wrapper.findComponent(GlLink).attributes('href')).toBe('test');
  });

  it('emits `close` event when drawer is closed', () => {
    createComponent({ open: true });

    findGlDrawer().vm.$emit('close');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });

  it('passes listeners correctly to WorkItemDetail', () => {
    createComponent({ open: true });
    const mockPayload = { iid: '1' };

    findWorkItem().vm.$emit('customEvent', mockPayload);

    expect(mockListener).toHaveBeenCalledWith(mockPayload);
  });
});
