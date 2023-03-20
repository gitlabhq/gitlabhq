import { GlBanner } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import UpgradeBanner, {
  SECURITY_UPGRADE_BANNER,
  UPGRADE_OR_FREE_TRIAL,
} from '~/security_configuration/components/upgrade_banner.vue';

const upgradePath = '/upgrade';

describe('UpgradeBanner component', () => {
  let wrapper;
  let closeSpy;
  let primarySpy;
  let trackingSpy;

  const createComponent = (propsData) => {
    closeSpy = jest.fn();
    primarySpy = jest.fn();

    wrapper = shallowMountExtended(UpgradeBanner, {
      provide: {
        upgradePath,
      },
      propsData,
      listeners: {
        close: closeSpy,
        primary: primarySpy,
      },
    });
  };

  const findGlBanner = () => wrapper.findComponent(GlBanner);

  const expectTracking = (action, label) => {
    return expect(trackingSpy).toHaveBeenCalledWith(undefined, action, {
      label,
      property: SECURITY_UPGRADE_BANNER,
    });
  };

  beforeEach(() => {
    trackingSpy = mockTracking(undefined, undefined, jest.spyOn);
  });

  afterEach(() => {
    unmockTracking();
  });

  describe('when the component renders', () => {
    it('tracks an event', () => {
      expect(trackingSpy).not.toHaveBeenCalled();

      createComponent();

      expectTracking('render', SECURITY_UPGRADE_BANNER);
    });
  });

  describe('when ready', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy.mockClear();
    });

    it('passes the expected props to GlBanner', () => {
      expect(findGlBanner().props()).toMatchObject({
        title: UpgradeBanner.i18n.title,
        buttonText: UpgradeBanner.i18n.buttonText,
        buttonLink: upgradePath,
      });
    });

    it('renders the list of benefits', () => {
      const wrapperText = wrapper.text();

      expect(wrapperText).toContain('Immediately begin risk analysis and remediation');
      expect(wrapperText).toContain('statistics in the merge request');
      expect(wrapperText).toContain('statistics across projects');
      expect(wrapperText).toContain('Runtime security metrics');
      expect(wrapperText).toContain('More scan types, including DAST,');
    });

    describe('when user interacts', () => {
      it(`re-emits GlBanner's close event & tracks an event`, () => {
        expect(closeSpy).not.toHaveBeenCalled();
        expect(trackingSpy).not.toHaveBeenCalled();

        wrapper.findComponent(GlBanner).vm.$emit('close');

        expect(closeSpy).toHaveBeenCalledTimes(1);
        expectTracking('dismiss_banner', SECURITY_UPGRADE_BANNER);
      });

      it(`re-emits GlBanner's primary event & tracks an event`, () => {
        expect(primarySpy).not.toHaveBeenCalled();
        expect(trackingSpy).not.toHaveBeenCalled();

        wrapper.findComponent(GlBanner).vm.$emit('primary');

        expect(primarySpy).toHaveBeenCalledTimes(1);
        expectTracking('click_button', UPGRADE_OR_FREE_TRIAL);
      });
    });
  });
});
