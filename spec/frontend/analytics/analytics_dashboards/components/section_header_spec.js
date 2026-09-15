import { GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SectionHeader from '~/analytics/analytics_dashboards/components/section_header.vue';

describe('SectionHeader', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;

  const findTitle = () => wrapper.findByTestId('section-header-title');
  const findDescription = () => wrapper.findByTestId('section-header-description');
  const findDivider = () => wrapper.findByTestId('section-header-divider');
  const findTooltipIcon = () => wrapper.findComponentByTestId('section-header-tooltip-icon');
  const findPopover = () => wrapper.findComponent(GlPopover);

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(SectionHeader, {
      propsData: {
        title: 'Adoption tiers',
        description: 'How engagement is distributed',
        ...props,
      },
    });
  };

  describe('default', () => {
    beforeEach(() => createWrapper());

    it('renders the title', () => {
      expect(findTitle().text()).toBe('Adoption tiers');
    });

    it('renders the description', () => {
      expect(findDescription().text()).toBe('How engagement is distributed');
    });

    it('does not render a tooltip', () => {
      expect(findTooltipIcon().exists()).toBe(false);
      expect(findPopover().exists()).toBe(false);
    });

    it('renders without a panel border or horizontal padding', () => {
      const classes = wrapper.attributes('class');
      expect(classes).toContain('gl-px-0');
      expect(classes).not.toContain('gl-border');
    });

    it('renders the heading inside the divider', () => {
      expect(findDivider().find('[data-testid="section-header-title"]').exists()).toBe(true);
    });
  });

  describe('with a tooltip', () => {
    const tooltip = { title: 'Adoption tiers', description: 'Light 1-4, Regular 5-24' };

    beforeEach(() => createWrapper({ tooltip }));

    it('renders the icon the popover targets', () => {
      expect(findTooltipIcon().props('name')).toBe('information-o');
    });

    // GlIcon renders `aria-hidden` unless it is given a label, so a focusable icon
    // without one announces nothing -- which is what the storybook axe check fails on.
    it('names the icon after its section', () => {
      expect(findTooltipIcon().props('ariaLabel')).toBe('More information about Adoption tiers');
    });

    it('passes the tooltip title to the popover', () => {
      expect(findPopover().props('title')).toBe(tooltip.title);
    });

    it('targets the popover at the icon', () => {
      expect(findPopover().props('target')).toBe(findTooltipIcon().attributes('id'));
    });

    it('renders the tooltip description inside the popover', () => {
      expect(findPopover().text()).toBe(tooltip.description);
    });
  });
});
