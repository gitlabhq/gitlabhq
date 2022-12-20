import { GlAlert, GlButton, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import SecurityPatchUpgradeAlert from '~/gitlab_version_check/components/security_patch_upgrade_alert.vue';
import { UPGRADE_DOCS_URL, ABOUT_RELEASES_PAGE } from '~/gitlab_version_check/constants';

describe('SecurityPatchUpgradeAlert', () => {
  let wrapper;
  let trackingSpy;

  const defaultProps = {
    currentVersion: '99.9',
  };

  const createComponent = () => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);

    wrapper = shallowMount(SecurityPatchUpgradeAlert, {
      propsData: {
        ...defaultProps,
      },
      stubs: {
        GlAlert,
        GlSprintf,
      },
    });
  };

  afterEach(() => {
    unmockTracking();
  });

  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const findGlButton = () => wrapper.findComponent(GlButton);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders non-dismissible GlAlert with version information', () => {
      expect(findGlAlert().text()).toContain(
        `You are currently on version ${defaultProps.currentVersion}.`,
      );
      expect(findGlAlert().props('dismissible')).toBe(false);
    });

    it('tracks render security_patch_upgrade_alert correctly', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'render', {
        label: 'security_patch_upgrade_alert',
        property: defaultProps.currentVersion,
      });
    });

    it('renders GlLink with correct text and link', () => {
      expect(findGlLink().text()).toBe('Learn more about this critical security release.');
      expect(findGlLink().attributes('href')).toBe(ABOUT_RELEASES_PAGE);
    });

    it('tracks click security_patch_upgrade_alert_learn_more when link is clicked', async () => {
      await findGlLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
        label: 'security_patch_upgrade_alert_learn_more',
        property: defaultProps.currentVersion,
      });
    });

    it('renders GlButton with correct text and link', () => {
      expect(findGlButton().text()).toBe('Upgrade now');
      expect(findGlButton().attributes('href')).toBe(UPGRADE_DOCS_URL);
    });

    it('tracks click security_patch_upgrade_alert_upgrade_now when button is clicked', async () => {
      await findGlButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'click_link', {
        label: 'security_patch_upgrade_alert_upgrade_now',
        property: defaultProps.currentVersion,
      });
    });
  });
});
