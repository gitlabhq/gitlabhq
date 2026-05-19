import { GlIcon, GlLink, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ScanTypeCell from '~/security_configuration/components/scan_profiles/scan_type_cell.vue';
import {
  SCAN_PROFILE_SCANNER_HEALTH_ACTIVE,
  SCAN_PROFILE_SCANNER_HEALTH_FAILED,
  SCAN_PROFILE_SCANNER_HEALTH_PENDING,
  SCAN_PROFILE_SCANNER_HEALTH_STALE,
  SCAN_PROFILE_SCANNER_HEALTH_UNCONFIGURED,
  SCAN_PROFILE_SCANNER_HEALTH_WARNING,
} from '~/security_configuration/constants';

const baseClasses =
  'gl-border gl-mr-3 gl-flex gl-h-7 gl-w-7 gl-items-center gl-justify-center gl-rounded-lg gl-p-2'.split(
    ' ',
  );

describe('ScanTypeCell', () => {
  let wrapper;

  const createComponent = (props = {}, glFeatures = {}) => {
    wrapper = mountExtended(ScanTypeCell, {
      propsData: {
        scanType: 'SAST',
        ...props,
      },
      provide: { glFeatures },
    });
  };

  const findBadge = () => wrapper.findByTestId('scan-type-badge');
  const findDisplayName = () => wrapper.find('.gl-font-bold');
  const findInfoIcon = () => wrapper.findComponent(GlIcon);
  const findPopover = () => wrapper.findComponent(GlPopover);
  const findPopoverLink = () => wrapper.findComponent(GlLink);

  describe('scanner badge', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the scanner type label', () => {
      expect(findBadge().text()).toBe('SAST');
    });

    it('renders the scanner display name', () => {
      expect(findDisplayName().text()).toBe('Static Application Security Testing (SAST)');
    });

    describe('with securityScanProfilesStatusIndicators feature flag', () => {
      it.each`
        status                                      | statusClasses
        ${SCAN_PROFILE_SCANNER_HEALTH_ACTIVE}       | ${['gl-border-feedback-success', 'gl-bg-status-success', 'gl-text-status-success']}
        ${SCAN_PROFILE_SCANNER_HEALTH_WARNING}      | ${['gl-border-feedback-warning', 'gl-bg-status-warning', 'gl-text-status-warning']}
        ${SCAN_PROFILE_SCANNER_HEALTH_FAILED}       | ${['gl-border-feedback-danger', 'gl-bg-status-danger', 'gl-text-status-danger']}
        ${SCAN_PROFILE_SCANNER_HEALTH_PENDING}      | ${['gl-border-strong', 'gl-bg-status-neutral', 'gl-text-strong']}
        ${SCAN_PROFILE_SCANNER_HEALTH_STALE}        | ${['gl-border-strong', 'gl-bg-status-neutral', 'gl-text-strong']}
        ${SCAN_PROFILE_SCANNER_HEALTH_UNCONFIGURED} | ${['gl-border-dashed', 'gl-border-strong', 'gl-bg-default', 'gl-text-strong']}
        ${null}                                     | ${['gl-border-dashed', 'gl-border-strong', 'gl-bg-default', 'gl-text-strong']}
      `('applies correct styling for "$status" status', ({ status, statusClasses }) => {
        createComponent({ status }, { securityScanProfilesStatusIndicators: true });

        expect(findBadge().classes()).toEqual([...baseClasses, ...statusClasses]);
      });
    });

    describe('when securityScanProfilesStatusIndicators feature flag is off', () => {
      it('returns configured classes when item is configured', () => {
        createComponent({ isConfigured: true }, { securityScanProfilesStatusIndicators: false });

        expect(findBadge().classes()).toEqual([
          ...baseClasses,
          'gl-border-green-500',
          'gl-bg-green-100',
          'gl-text-green-800',
        ]);
      });

      it('returns unconfigured classes when item is not configured', () => {
        createComponent({ isConfigured: false }, { securityScanProfilesStatusIndicators: false });

        expect(findBadge().classes()).toEqual([
          ...baseClasses,
          'gl-border-dashed',
          'gl-border-strong',
          'gl-bg-default',
          'gl-text-strong',
        ]);
      });
    });
  });

  describe('info popover', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an info icon', () => {
      expect(findInfoIcon().props('name')).toBe('information-o');
    });

    it('renders a popover with the scanner help title and description', () => {
      expect(findPopover().props('title')).toBe('What is SAST?');
      expect(findPopover().text()).toContain('Learn more');
    });

    it('renders a link to the scanner help page within the popover', () => {
      expect(findPopoverLink().attributes('href')).toBe(
        '/help/user/application_security/sast/_index',
      );
    });
  });
});
