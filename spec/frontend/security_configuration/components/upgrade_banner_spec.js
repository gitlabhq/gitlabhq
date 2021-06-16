import { GlBanner } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import UpgradeBanner from '~/security_configuration/components/upgrade_banner.vue';

const upgradePath = '/upgrade';

describe('UpgradeBanner component', () => {
  let wrapper;
  let closeSpy;

  const createComponent = (propsData) => {
    closeSpy = jest.fn();

    wrapper = shallowMountExtended(UpgradeBanner, {
      provide: {
        upgradePath,
      },
      propsData,
      listeners: {
        close: closeSpy,
      },
    });
  };

  const findGlBanner = () => wrapper.findComponent(GlBanner);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
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

    expect(wrapperText).toContain('GitLab Ultimate checks your application');
    expect(wrapperText).toContain('statistics in the merge request');
    expect(wrapperText).toContain('statistics across projects');
    expect(wrapperText).toContain('Runtime security metrics');
    expect(wrapperText).toContain('risk analysis and remediation');
  });

  it(`re-emits GlBanner's close event`, () => {
    expect(closeSpy).not.toHaveBeenCalled();

    wrapper.findComponent(GlBanner).vm.$emit('close');

    expect(closeSpy).toHaveBeenCalledTimes(1);
  });
});
