import { GlLink, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { PROMO_URL } from '~/constants';
import ScanProfileConfiguration from '~/security_configuration/components/scan_profiles/scan_profile_configuration.vue';
import ScanProfileTable from '~/security_configuration/components/scan_profiles/scan_profile_table.vue';
import {
  SCAN_PROFILE_CATEGORIES,
  SCAN_PROFILE_TYPE_SECRET_DETECTION,
} from '~/security_configuration/constants';

describe('ScanProfileConfiguration', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(ScanProfileConfiguration, {
      provide: {
        canApplyProfiles: false,
        securityScanProfilesLicensed: false,
      },
    });

    return wrapper;
  };

  const findTable = () => wrapper.findComponent(ScanProfileTable);
  const findLink = () => wrapper.findComponent(GlLink);
  const findButtonAt = (i) => wrapper.findAllComponents(GlButton).at(i);

  describe('table rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders table with correct items', () => {
      const table = findTable();

      expect(table.props('tableItems')).toEqual([
        {
          scanType: SCAN_PROFILE_TYPE_SECRET_DETECTION,
          isConfigured: false,
        },
      ]);
    });

    it('renders Secret Detection with "No profile applied"', () => {
      expect(wrapper.text()).toContain(
        SCAN_PROFILE_CATEGORIES[SCAN_PROFILE_TYPE_SECRET_DETECTION].label,
      );
      expect(wrapper.text()).toContain(
        SCAN_PROFILE_CATEGORIES[SCAN_PROFILE_TYPE_SECRET_DETECTION].name,
      );
      expect(wrapper.text()).toContain('No profile applied');
    });

    it('renders a link to learn more about scan profiles', () => {
      expect(wrapper.text()).toContain('Available with Ultimate');
      expect(findLink().text()).toBe('Learn more about the Ultimate security suite');
      expect(findLink().props('href')).toBe(`${PROMO_URL}/solutions/application-security-testing/`);
    });

    it('renders disabled buttons', () => {
      expect(findButtonAt(0).text()).toBe('Apply default profile');
      expect(findButtonAt(0).props('disabled')).toBe(true);
      expect(findButtonAt(1).props('icon')).toBe('eye');
      expect(findButtonAt(1).props('disabled')).toBe(true);
    });
  });
});
