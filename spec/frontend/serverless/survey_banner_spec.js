import { GlBanner } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import SurveyBanner from '~/serverless/survey_banner.vue';

describe('Knative survey banner', () => {
  let wrapper;

  function mountBanner() {
    wrapper = shallowMount(SurveyBanner, {
      propsData: {
        surveyUrl: 'http://somesurvey.com/',
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render the banner when the cookie is absent', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue(undefined);
    mountBanner();

    expect(Cookies.get).toHaveBeenCalled();
    expect(wrapper.find(GlBanner).exists()).toBe(true);
  });

  it('should close the banner and set a cookie when close button is clicked', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue(undefined);
    jest.spyOn(Cookies, 'set');
    mountBanner();

    expect(wrapper.find(GlBanner).exists()).toBe(true);
    wrapper.find(GlBanner).vm.$emit('close');

    return wrapper.vm.$nextTick().then(() => {
      expect(Cookies.set).toHaveBeenCalledWith('hide_serverless_survey', 'true', { expires: 3650 });
      expect(wrapper.find(GlBanner).exists()).toBe(false);
    });
  });

  it('should not render the banner when the cookie is set', () => {
    jest.spyOn(Cookies, 'get').mockReturnValue('true');
    mountBanner();

    expect(Cookies.get).toHaveBeenCalled();
    expect(wrapper.find(GlBanner).exists()).toBe(false);
  });
});
