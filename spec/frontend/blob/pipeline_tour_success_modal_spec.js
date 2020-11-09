import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import { GlSprintf, GlModal, GlLink } from '@gitlab/ui';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';
import pipelineTourSuccess from '~/blob/pipeline_tour_success_modal.vue';
import modalProps from './pipeline_tour_success_mock_data';

describe('PipelineTourSuccessModal', () => {
  let wrapper;
  let cookieSpy;
  let trackingSpy;

  const createComponent = () => {
    wrapper = shallowMount(pipelineTourSuccess, {
      propsData: modalProps,
      stubs: {
        GlModal,
        GlSprintf,
        'gl-emoji': '<img/>',
      },
    });
  };

  beforeEach(() => {
    document.body.dataset.page = 'projects:blob:show';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);
    cookieSpy = jest.spyOn(Cookies, 'remove');
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
    Cookies.remove(modalProps.commitCookie);
  });

  describe('when the commitCookie contains the mr path', () => {
    const expectedMrPath = 'expected_mr_path';

    beforeEach(() => {
      Cookies.set(modalProps.commitCookie, expectedMrPath);
      createComponent();
    });

    it('renders the path from the commit cookie for back to the merge request button', () => {
      const goToMrBtn = wrapper.find({ ref: 'goToMergeRequest' });

      expect(goToMrBtn.attributes('href')).toBe(expectedMrPath);
    });
  });

  describe('when the commitCookie does not contain mr path', () => {
    const expectedMrPath = modalProps.projectMergeRequestsPath;

    beforeEach(() => {
      Cookies.set(modalProps.commitCookie, true);
      createComponent();
    });

    it('renders the path from projectMergeRequestsPath for back to the merge request button', () => {
      const goToMrBtn = wrapper.find({ ref: 'goToMergeRequest' });

      expect(goToMrBtn.attributes('href')).toBe(expectedMrPath);
    });
  });

  it('has expected structure', () => {
    const modal = wrapper.find(GlModal);
    const sprintf = modal.find(GlSprintf);
    const emoji = modal.find('img');

    expect(wrapper.text()).toContain("That's it, well done!");
    expect(sprintf.exists()).toBe(true);
    expect(emoji.exists()).toBe(true);
  });

  it('renders the link for codeQualityLink', () => {
    expect(wrapper.find(GlLink).attributes('href')).toBe('/code-quality-link');
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
      const goToBtn = wrapper.find({ ref: 'goToPipelines' });
      triggerEvent(goToBtn.element);

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'congratulate_first_pipeline',
        property: modalProps.humanAccess,
        value: '10',
      });
    });

    it('sends an event when back to the merge request is clicked', () => {
      trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
      const goToBtn = wrapper.find({ ref: 'goToMergeRequest' });
      triggerEvent(goToBtn.element);

      expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
        label: 'congratulate_first_pipeline',
        property: modalProps.humanAccess,
        value: '20',
      });
    });
  });
});
