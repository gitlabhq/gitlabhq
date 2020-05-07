import pipelineTourSuccess from '~/blob/pipeline_tour_success_modal.vue';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import { GlSprintf, GlModal } from '@gitlab/ui';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';
import modalProps from './pipeline_tour_success_mock_data';

describe('PipelineTourSuccessModal', () => {
  let wrapper;
  let cookieSpy;
  let trackingSpy;

  beforeEach(() => {
    document.body.dataset.page = 'projects:blob:show';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

    wrapper = shallowMount(pipelineTourSuccess, {
      propsData: modalProps,
      stubs: {
        GlModal,
      },
    });

    cookieSpy = jest.spyOn(Cookies, 'remove');
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  it('has expected structure', () => {
    const modal = wrapper.find(GlModal);
    const sprintf = modal.find(GlSprintf);

    expect(modal.attributes('title')).toContain("That's it, well done!");
    expect(sprintf.exists()).toBe(true);
  });

  it('calls to remove cookie', () => {
    wrapper.vm.disableModalFromRenderingAgain();

    expect(cookieSpy).toHaveBeenCalledWith(modalProps.commitCookie);
  });

  describe('tracking', () => {
    it('send event for basic view of modal', () => {
      expect(trackingSpy).toHaveBeenCalledWith(undefined, undefined, {
        label: 'congratulate_first_pipeline',
        property: modalProps.humanAccess,
      });
    });

    it('send an event when go to pipelines is clicked', () => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
      const goToBtn = wrapper.find({ ref: 'goto' });
      triggerEvent(goToBtn.element);

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'congratulate_first_pipeline',
        property: modalProps.humanAccess,
        value: '10',
      });
    });
  });
});
