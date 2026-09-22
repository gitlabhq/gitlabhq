import { nextTick } from 'vue';
import { GlAlert, GlCollapse } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DiagnosticsSection from '~/admin/database_diagnostics/components/diagnostics_section.vue';

describe('DiagnosticsSection component', () => {
  let wrapper;

  const findings = [
    { severity: 'error', code: 'an_error', message: 'an error' },
    { severity: 'warning', code: 'a_warning', message: 'a warning' },
  ];

  const findStatusIcon = () => wrapper.findComponentByTestId('check-status-icon');
  const findCountBadge = () => wrapper.findComponentByTestId('check-count');
  const findToggle = () => wrapper.findComponentByTestId('check-toggle');
  const findCollapse = () => wrapper.findComponent(GlCollapse);
  const findAllAlerts = () => wrapper.findAllComponents(GlAlert);

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(DiagnosticsSection, {
      propsData: {
        title: 'Search path',
        testidPrefix: 'check',
        ...props,
      },
      slots: {
        default: '<p data-testid="body">details</p>',
      },
    });
  };

  const expand = async () => {
    findToggle().vm.$emit('click');
    await nextTick();
  };

  describe('by default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the title and a green status icon', () => {
      expect(wrapper.text()).toContain('Search path');
      expect(findStatusIcon().props('variant')).toBe('success');
      expect(findStatusIcon().props('name')).toBe('check-circle-filled');
    });

    it('renders no count badge and no alerts', () => {
      expect(findCountBadge().exists()).toBe(false);
      expect(findAllAlerts()).toHaveLength(0);
    });

    it('renders the slot content, collapsed until toggled', async () => {
      expect(wrapper.findByTestId('body').exists()).toBe(true);
      expect(findCollapse().props('visible')).toBe(false);

      await expand();

      expect(findCollapse().props('visible')).toBe(true);
    });

    it('exposes the expanded state to assistive technology', async () => {
      expect(findToggle().attributes('aria-expanded')).toBe('false');
      expect(findToggle().attributes('aria-controls')).toBe(findCollapse().attributes('id'));

      await expand();

      expect(findToggle().attributes('aria-expanded')).toBe('true');
    });
  });

  describe('with findings', () => {
    beforeEach(() => {
      createComponent({ severity: 'error', findings });
    });

    it('reflects the severity in the status icon and the count badge', () => {
      expect(findStatusIcon().props('variant')).toBe('danger');
      expect(findStatusIcon().props('name')).toBe('error');
      expect(findCountBadge().text()).toBe('2');
    });

    it('renders one alert per finding, in the order supplied', () => {
      const alerts = findAllAlerts().wrappers;

      expect(alerts).toHaveLength(2);
      expect(wrapper.findByTestId('check-finding-an_error').exists()).toBe(true);
      expect(alerts[0].props('variant')).toBe('danger');
      expect(alerts[0].text()).toBe('an error');
      expect(alerts[1].props('variant')).toBe('warning');
      expect(alerts[1].text()).toBe('a warning');
    });

    it('renders a warning status icon for a warning severity', () => {
      createComponent({ severity: 'warning', findings });

      expect(findStatusIcon().props('variant')).toBe('warning');
      expect(findStatusIcon().props('name')).toBe('warning');
    });

    it('falls back to a warning status icon for an unknown severity', () => {
      createComponent({ severity: 'info', findings });

      expect(findStatusIcon().props('variant')).toBe('warning');
      expect(findStatusIcon().props('name')).toBe('warning');
      expect(findCountBadge().props('variant')).toBe('warning');
    });

    it('keeps the count badge but drops the alerts when the caller renders findings itself', () => {
      createComponent({ severity: 'error', findings, showFindingAlerts: false });

      expect(findCountBadge().text()).toBe('2');
      expect(findAllAlerts()).toHaveLength(0);
    });
  });

  describe('with a count of its own', () => {
    it('shows the count instead of the number of findings, in the severity variant', () => {
      createComponent({ severity: 'error', findings, count: 7 });

      expect(findCountBadge().text()).toBe('7');
      expect(findCountBadge().props('variant')).toBe('danger');
    });

    it('renders a neutral badge when there is a count but no severity', () => {
      createComponent({ count: 3 });

      expect(findCountBadge().text()).toBe('3');
      expect(findCountBadge().props('variant')).toBe('neutral');
      expect(findStatusIcon().props('variant')).toBe('success');
    });
  });

  describe('when not foldable', () => {
    beforeEach(() => {
      createComponent({ foldable: false, severity: 'warning', findings });
    });

    it('renders neither the status icon, the toggle, nor the details', () => {
      expect(findStatusIcon().exists()).toBe(false);
      expect(findToggle().exists()).toBe(false);
      expect(findCollapse().exists()).toBe(false);
      expect(wrapper.findByTestId('body').exists()).toBe(false);
    });

    it('still reports the finding count', () => {
      expect(findCountBadge().text()).toBe('2');
    });
  });
});
