import { shallowMount } from '@vue/test-utils';
import { GlIcon } from '@gitlab/ui';
import { nextTick } from 'vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';

import CollapsedCalendarIcon from '~/vue_shared/components/sidebar/collapsed_calendar_icon.vue';

describe('CollapsedCalendarIcon', () => {
  let wrapper;

  const defaultProps = {
    containerClass: 'test-class',
    text: 'text',
    tooltipText: 'tooltip text',
    showIcon: false,
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMount(CollapsedCalendarIcon, {
      propsData: { ...defaultProps, ...props },
      directives: {
        GlTooltip: createMockDirective(),
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findGlIcon = () => wrapper.findComponent(GlIcon);
  const getTooltip = () => getBinding(wrapper.element, 'gl-tooltip');

  it('adds class to container', () => {
    expect(wrapper.classes()).toContain(defaultProps.containerClass);
  });

  it('does not render calendar icon when showIcon is false', () => {
    expect(findGlIcon().exists()).toBe(false);
  });

  it('renders calendar icon when showIcon is true', () => {
    createComponent({
      props: { showIcon: true },
    });

    expect(findGlIcon().exists()).toBe(true);
  });

  it('renders text', () => {
    expect(wrapper.text()).toBe(defaultProps.text);
  });

  it('renders tooltipText as tooltip', () => {
    expect(getTooltip().value).toBe(defaultProps.tooltipText);
  });

  it('emits click event when container is clicked', async () => {
    wrapper.trigger('click');

    await nextTick();

    expect(wrapper.emitted('click')[0]).toBeDefined();
  });
});
