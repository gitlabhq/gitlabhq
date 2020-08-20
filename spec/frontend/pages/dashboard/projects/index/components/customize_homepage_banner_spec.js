import { shallowMount } from '@vue/test-utils';
import { GlBanner } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import CustomizeHomepageBanner from '~/pages/dashboard/projects/index/components/customize_homepage_banner.vue';
import axios from '~/lib/utils/axios_utils';

const svgPath = '/illustrations/background';
const provide = {
  svgPath,
  preferencesBehaviorPath: 'some/behavior/path',
  calloutsPath: 'call/out/path',
  calloutsFeatureId: 'some-feature-id',
};

const createComponent = () => {
  return shallowMount(CustomizeHomepageBanner, { provide });
};

describe('CustomizeHomepageBanner', () => {
  let mockAxios;
  let wrapper;

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    mockAxios.restore();
  });

  it('should render the banner when not dismissed', () => {
    expect(wrapper.contains(GlBanner)).toBe(true);
  });

  it('should close the banner when dismiss is clicked', async () => {
    mockAxios.onPost(provide.calloutsPath).replyOnce(200);
    expect(wrapper.contains(GlBanner)).toBe(true);
    wrapper.find(GlBanner).vm.$emit('close');

    await wrapper.vm.$nextTick();
    expect(wrapper.contains(GlBanner)).toBe(false);
  });

  it('includes the body text from options', () => {
    expect(wrapper.html()).toContain(wrapper.vm.$options.i18n.body);
  });
});
