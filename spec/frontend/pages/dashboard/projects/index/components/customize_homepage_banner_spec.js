import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { mockTracking, unmockTracking, triggerEvent } from 'helpers/tracking_helper';
import axios from '~/lib/utils/axios_utils';
import CustomizeHomepageBanner from '~/pages/dashboard/projects/index/components/customize_homepage_banner.vue';

const svgPath = '/illustrations/background';
const provide = {
  svgPath,
  preferencesBehaviorPath: 'some/behavior/path',
  calloutsPath: 'call/out/path',
  calloutsFeatureId: 'some-feature-id',
  trackLabel: 'home_page',
};

const createComponent = () => {
  return shallowMount(CustomizeHomepageBanner, { provide, stubs: { GlBanner } });
};

describe('CustomizeHomepageBanner', () => {
  let trackingSpy;
  let mockAxios;
  let wrapper;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    document.body.dataset.page = 'some:page';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
    unmockTracking();
  });

  it('should render the banner when not dismissed', () => {
    expect(wrapper.find(GlBanner).exists()).toBe(true);
  });

  it('should close the banner when dismiss is clicked', async () => {
    mockAxios.onPost(provide.calloutsPath).replyOnce(200);
    expect(wrapper.find(GlBanner).exists()).toBe(true);
    wrapper.find(GlBanner).vm.$emit('close');

    await wrapper.vm.$nextTick();
    expect(wrapper.find(GlBanner).exists()).toBe(false);
  });

  it('includes the body text from options', () => {
    expect(wrapper.html()).toContain(wrapper.vm.$options.i18n.body);
  });

  describe('tracking', () => {
    const preferencesTrackingEvent = 'click_go_to_preferences';
    const mockTrackingOnWrapper = () => {
      unmockTracking();
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
    };

    it('sets the needed data attributes for tracking button', async () => {
      await wrapper.vm.$nextTick();
      const button = wrapper.find(`[href='${wrapper.vm.preferencesBehaviorPath}']`);

      expect(button.attributes('data-track-event')).toEqual(preferencesTrackingEvent);
      expect(button.attributes('data-track-label')).toEqual(provide.trackLabel);
    });

    it('sends a tracking event when the banner is shown', () => {
      const trackCategory = undefined;
      const trackEvent = 'show_home_page_banner';

      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, trackEvent, {
        label: provide.trackLabel,
      });
    });

    it('sends a tracking event when the banner is dismissed', async () => {
      mockTrackingOnWrapper();
      mockAxios.onPost(provide.calloutsPath).replyOnce(200);
      const trackCategory = undefined;
      const trackEvent = 'click_dismiss';

      wrapper.find(GlBanner).vm.$emit('close');

      await wrapper.vm.$nextTick();
      expect(trackingSpy).toHaveBeenCalledWith(trackCategory, trackEvent, {
        label: provide.trackLabel,
      });
    });

    it('sends a tracking event when the button is clicked', async () => {
      mockTrackingOnWrapper();
      mockAxios.onPost(provide.calloutsPath).replyOnce(200);
      const button = wrapper.find(`[href='${wrapper.vm.preferencesBehaviorPath}']`);

      triggerEvent(button.element);

      await wrapper.vm.$nextTick();
      expect(trackingSpy).toHaveBeenCalledWith('_category_', preferencesTrackingEvent, {
        label: provide.trackLabel,
      });
    });
  });
});
