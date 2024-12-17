import { GlIcon, GlTooltip, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemAttribute from '~/vue_shared/components/work_item_attribute.vue';

describe('WorkItemAttribute Component', () => {
  let wrapper;

  const createComponent = (propsData = {}, scopedSlots = {}) => {
    wrapper = shallowMountExtended(WorkItemAttribute, {
      propsData,
      scopedSlots,
      stubs: { GlTooltip, GlIcon, GlLink },
    });
  };

  const findWrapper = () => wrapper.findComponent({ ref: 'wrapperRef' });
  const findIcon = () => wrapper.findComponent(GlIcon);
  const findTooltip = () => wrapper.findComponent(GlTooltip);
  const findLink = () => wrapper.findComponent(GlLink);

  it('renders the wrapper component with correct class and attributes', () => {
    createComponent({
      wrapperComponent: 'div',
      wrapperComponentClass: 'custom-class',
      anchorId: 'test-id',
    });

    const wrapperEl = findWrapper();
    expect(wrapperEl.exists()).toBe(true);
    expect(wrapperEl.classes()).toContain('custom-class');
    expect(wrapperEl.attributes('data-testid')).toBe('test-id');
  });

  it('renders the default wrapper component when none is provided', () => {
    createComponent();

    const wrapperEl = findWrapper();
    expect(wrapperEl.exists()).toBe(true);
    expect(wrapperEl.element.tagName.toLowerCase()).toBe('span');
  });

  it('renders the icon with correct props when `iconName` is provided', () => {
    createComponent({
      iconName: 'rocket',
      iconClass: 'custom-icon-class',
      anchorId: 'test-anchor',
    });

    const icon = findIcon();
    expect(icon.exists()).toBe(true);
    expect(icon.props('name')).toBe('rocket');
    expect(icon.classes()).toContain('custom-icon-class');
    expect(icon.attributes('data-testid')).toBe('test-anchor-icon');
  });

  it('does not render the icon if `iconName` is not provided', () => {
    createComponent();

    expect(findIcon().exists()).toBe(false);
  });

  it('renders the title text when `title` is provided and no slot is used', () => {
    createComponent({
      title: 'Test Title',
      titleComponentClass: 'title-class',
      anchorId: 'test-anchor',
    });

    const titleEl = wrapper.find('span.title-class');
    expect(titleEl.exists()).toBe(true);
    expect(titleEl.text()).toBe('Test Title');
    expect(titleEl.attributes('data-testid')).toBe('test-anchor-title');
  });

  it('renders the title slot if provided', () => {
    createComponent({}, { title: '<span>Slot Title</span>' });

    expect(wrapper.find('span').text()).toBe('Slot Title');
  });

  it('renders the tooltip with correct text when `tooltipText` is provided', () => {
    createComponent({ tooltipText: 'Tooltip content', tooltipPlacement: 'top' });

    const tooltip = findTooltip();
    expect(tooltip.exists()).toBe(true);
    expect(tooltip.props('placement')).toBe('top');
    expect(tooltip.text()).toBe('Tooltip content');
  });

  it('renders the tooltip slot if provided', () => {
    createComponent({}, { 'tooltip-text': '<span>Slot Tooltip</span>' });

    const tooltip = findTooltip();
    expect(tooltip.exists()).toBe(true);
    expect(tooltip.text()).toBe('Slot Tooltip');
  });

  it('binds the tooltip target correctly', () => {
    createComponent();

    const tooltip = findTooltip();
    expect(tooltip.props('target')()).toBe(findWrapper().element);
  });

  describe('when `isLink` prop is true', () => {
    it('renders GlLink component instead of span', () => {
      createComponent({ isLink: true, href: 'https://example.com' });

      const link = findLink();
      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe('https://example.com');
    });

    it('does not render GlLink when `isLink` is false', () => {
      createComponent({ isLink: false });

      expect(findLink().exists()).toBe(false);
    });

    it('renders the wrapper component inside the GlLink', () => {
      createComponent({ isLink: true });

      const link = findLink();
      expect(link.exists()).toBe(true);
      expect(findWrapper().exists()).toBe(true);
    });
  });

  describe('when slots are provided', () => {
    it('renders icon slot if provided', () => {
      createComponent({}, { icon: '<gl-icon name="rocket"></gl-icon>' });

      const slotIcon = wrapper.findComponent(GlIcon);
      expect(slotIcon.exists()).toBe(true);
      expect(slotIcon.props('name')).toBe('rocket');
    });

    it('renders tooltip slot if provided', () => {
      createComponent({}, { 'tooltip-text': '<span>Custom Tooltip</span>' });

      const tooltip = findTooltip();
      expect(tooltip.exists()).toBe(true);
      expect(tooltip.text()).toBe('Custom Tooltip');
    });
  });
});
