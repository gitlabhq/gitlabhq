import pipelineTourSuccess from '~/blob/pipeline_tour_success_modal.vue';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import { GlSprintf, GlModal } from '@gitlab/ui';

describe('PipelineTourSuccessModal', () => {
  let wrapper;
  let cookieSpy;
  const goToPipelinesPath = 'some_pipeline_path';
  const commitCookie = 'some_cookie';

  beforeEach(() => {
    wrapper = shallowMount(pipelineTourSuccess, {
      propsData: {
        goToPipelinesPath,
        commitCookie,
      },
    });

    cookieSpy = jest.spyOn(Cookies, 'remove');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('has expected structure', () => {
    const modal = wrapper.find(GlModal);
    const sprintf = modal.find(GlSprintf);

    expect(modal.attributes('title')).toContain("That's it, well done!");
    expect(sprintf.exists()).toBe(true);
  });

  it('calls to remove cookie', () => {
    wrapper.vm.disableModalFromRenderingAgain();

    expect(cookieSpy).toHaveBeenCalledWith(commitCookie);
  });
});
