import { GlBanner, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import JHTransitionBanner from '~/admin/banners/jh_transition_banner/components/jh_transition_banner.vue';
import { transitionBannerTexts } from '~/admin/banners/jh_transition_banner/constants';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';

jest.mock('~/alert');

describe('JHTransitionBanner', () => {
  let wrapper;
  let userCalloutDismissSpy;
  const featureName = 'test-feature';

  const createComponent = (props = {}, shouldShowCallout = true) => {
    userCalloutDismissSpy = jest.fn();
    wrapper = shallowMount(JHTransitionBanner, {
      propsData: {
        featureName,
        userPreferredLanguage: 'en',
        ...props,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findBanner = () => wrapper.findComponent(GlBanner);

  describe('When language contains Chinese', () => {
    describe('When browser language contains Chinese', () => {
      const originalNavigator = global.navigator;
      beforeAll(() => {
        Object.defineProperty(global.navigator, 'languages', {
          value: ['zh-CN', 'zh', 'en'],
          configurable: true,
        });
      });

      afterAll(() => {
        delete global.navigator.languages;
        global.navigator = originalNavigator;
      });

      it('should render banner correctly', () => {
        createComponent();
        const banner = findBanner();
        expect(banner.exists()).toBe(true);
        expect(banner.props('title')).toBe(transitionBannerTexts.title);
        expect(banner.props('buttonText')).toBe(transitionBannerTexts.buttonText);
        expect(wrapper.findComponent(GlSprintf).attributes('message')).toBe(
          transitionBannerTexts.content,
        );
      });
    });

    describe('When user preferred language contains Chinese', () => {
      it('should render banner correctly', () => {
        createComponent({
          userPreferredLanguage: 'zh-CN',
        });

        expect(findBanner().exists()).toBe(true);
      });
    });

    describe('dismissing the alert', () => {
      beforeEach(() => {
        createComponent({
          userPreferredLanguage: 'zh-CN',
        });
        findBanner().vm.$emit('close');
      });

      it('calls the dismiss callback', () => {
        expect(userCalloutDismissSpy).toHaveBeenCalled();
      });
    });
  });

  describe('When language does not contain Chinese', () => {
    it('should not render banner', () => {
      createComponent();
      const banner = findBanner();

      expect(banner.exists()).toBe(false);
    });
  });
});
