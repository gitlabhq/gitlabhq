import { mount } from '@vue/test-utils';
import { GlBadge, GlPopover } from '@gitlab/ui';
import HoverBadge from '~/vue_shared/components/badges/hover_badge.vue';

describe('Hover badge component', () => {
  let wrapper;

  const findBadge = () => wrapper.findComponent(GlBadge);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const createWrapper = ({ props = {}, slots } = {}) => {
    wrapper = mount(HoverBadge, {
      propsData: {
        label: 'Label',
        title: 'Title',
        ...props,
      },
      slots,
    });
  };

  it('passes label to popover', () => {
    createWrapper();

    expect(findBadge().text()).toBe('Label');
  });

  it('passes title to popover', () => {
    createWrapper();

    expect(findPopover().props('title')).toBe('Title');
  });

  it('renders the default slot', () => {
    createWrapper({ slots: { default: '<p>This is an awesome content</p>' } });

    expect(findPopover().text()).toContain('This is an awesome content');
  });
});
