import { GlTooltip } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PlatformBadge from '~/packages_and_registries/container_registry/explorer/components/details_page/platform_badge.vue';
import { WINDOWS_BUILD_LABELS } from '~/packages_and_registries/container_registry/explorer/constants';

describe('PlatformBadge', () => {
  let wrapper;

  const createWrapper = (platform) => {
    wrapper = shallowMountExtended(PlatformBadge, {
      propsData: { platform },
    });
  };

  const findBadge = () => wrapper.findByTestId('platform-badge-text');

  describe('platformText', () => {
    it('renders os/architecture for linux/amd64', () => {
      createWrapper({ os: 'linux', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('linux/amd64');
    });

    it('renders os/architecture/variant for linux/arm64/v8', () => {
      createWrapper({ os: 'linux', architecture: 'arm64', variant: 'v8', osVersion: null });

      expect(findBadge().text()).toBe('linux/arm64/v8');
    });

    it('renders windows/amd64 with known build label', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.4529',
      });

      expect(findBadge().text()).toBe('windows/amd64 (ltsc2022)');
    });

    it('renders windows/amd64 without parenthetical for unknown build number', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.99999.0',
      });

      expect(findBadge().text()).toBe('windows/amd64 (99999)');
    });

    it('appends full osVersion for non-windows os', () => {
      createWrapper({
        os: 'linux',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.4529',
      });

      expect(findBadge().text()).toBe('linux/amd64 (10.0.20348.4529)');
    });

    describe('all known Windows build labels', () => {
      it.each(Object.entries(WINDOWS_BUILD_LABELS))(
        'build %s renders label %s',
        (buildNumber, label) => {
          createWrapper({
            os: 'windows',
            architecture: 'amd64',
            variant: null,
            osVersion: `10.0.${buildNumber}.0`,
          });

          expect(findBadge().text()).toBe(`windows/amd64 (${label})`);
        },
      );
    });

    it('handles null variant gracefully', () => {
      createWrapper({ os: 'linux', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('linux/amd64');
    });

    it('handles null osVersion gracefully', () => {
      createWrapper({ os: 'windows', architecture: 'amd64', variant: null, osVersion: null });

      expect(findBadge().text()).toBe('windows/amd64');
    });
  });
  describe('tooltip', () => {
    const findTooltip = () => wrapper.findComponent(GlTooltip);

    it('does not show a tooltip when osVersion is null', () => {
      createWrapper({ os: 'windows', architecture: 'amd64', variant: null, osVersion: null });

      expect(findTooltip().exists()).toBe(false);
      expect(findBadge().text()).toBe('windows/amd64');
    });

    it('does not show a tooltip for a known Windows build label', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.5139',
      });

      expect(findTooltip().exists()).toBe(false);
      expect(findBadge().text()).toBe('windows/amd64 (ltsc2022)');
    });

    it('shows a tooltip for an unknown Windows build number', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20420.1234',
      });

      expect(findTooltip().exists()).toBe(true);
      expect(findBadge().text()).toBe('windows/amd64 (20420)');
    });

    it('shows a tooltip for non-Windows with any osVersion', () => {
      createWrapper({
        os: 'linux',
        architecture: 'amd64',
        variant: null,
        osVersion: '10.0.20348.5139',
      });

      expect(findTooltip().exists()).toBe(true);
      expect(findBadge().text()).toBe('linux/amd64 (10.0.20348.5139)');
    });

    it('shows a tooltip for a non-standard osVersion', () => {
      createWrapper({
        os: 'windows',
        architecture: 'amd64',
        variant: null,
        osVersion: 'This is a test',
      });

      expect(findTooltip().exists()).toBe(true);
      expect(findBadge().text()).toBe('windows/amd64 (This is a test)');
    });
  });
});
