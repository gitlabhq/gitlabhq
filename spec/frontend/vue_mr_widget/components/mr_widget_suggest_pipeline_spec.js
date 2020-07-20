import { mount } from '@vue/test-utils';
import { GlLink, GlSprintf } from '@gitlab/ui';
import suggestPipelineComponent from '~/vue_merge_request_widget/components/mr_widget_suggest_pipeline.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';
import { popoverProps, iconName } from './pipeline_tour_mock_data';

describe('MRWidgetSuggestPipeline', () => {
  let wrapper;
  let trackingSpy;

  const mockTrackingOnWrapper = () => {
    unmockTracking();
    trackingSpy = mockTracking('_category_', wrapper.element, jest.spyOn);
  };

  beforeEach(() => {
    document.body.dataset.page = 'projects:merge_requests:show';
    trackingSpy = mockTracking('_category_', undefined, jest.spyOn);

    wrapper = mount(suggestPipelineComponent, {
      propsData: popoverProps,
      stubs: {
        GlSprintf,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
    unmockTracking();
  });

  describe('template', () => {
    const findOkBtn = () => wrapper.find('[data-testid="ok"]');

    it('renders add pipeline file link', () => {
      const link = wrapper.find(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes().href).toBe(popoverProps.pipelinePath);
    });

    it('renders the expected text', () => {
      const messageText = /\s*No pipeline\s*Add the .gitlab-ci.yml file\s*to create one./;

      expect(wrapper.text()).toMatch(messageText);
    });

    it('renders widget icon', () => {
      const icon = wrapper.find(MrWidgetIcon);

      expect(icon.exists()).toBe(true);
      expect(icon.props()).toEqual(
        expect.objectContaining({
          name: iconName,
        }),
      );
    });

    it('renders the show me how button', () => {
      const button = findOkBtn();

      expect(button.exists()).toBe(true);
      expect(button.classes('btn-info')).toEqual(true);
      expect(button.attributes('href')).toBe(popoverProps.pipelinePath);
    });

    it('renders the help link', () => {
      const link = wrapper.find('[data-testid="help"]');

      expect(link.exists()).toBe(true);
      expect(link.attributes('href')).toBe(wrapper.vm.$options.helpURL);
    });

    it('renders the empty pipelines image', () => {
      const image = wrapper.find('[data-testid="pipeline-image"]');

      expect(image.exists()).toBe(true);
      expect(image.attributes().src).toBe(popoverProps.pipelineSvgPath);
    });

    describe('tracking', () => {
      it('send event for basic view of the suggest pipeline widget', () => {
        const expectedCategory = undefined;
        const expectedAction = undefined;

        expect(trackingSpy).toHaveBeenCalledWith(expectedCategory, expectedAction, {
          label: wrapper.vm.$options.trackLabel,
          property: popoverProps.humanAccess,
        });
      });

      it('send an event when add pipeline link is clicked', () => {
        mockTrackingOnWrapper();
        const link = wrapper.find('[data-testid="add-pipeline-link"]');
        triggerEvent(link.element);

        expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_link', {
          label: wrapper.vm.$options.trackLabel,
          property: popoverProps.humanAccess,
          value: '30',
        });
      });

      it('send an event when ok button is clicked', () => {
        mockTrackingOnWrapper();
        const okBtn = findOkBtn();
        triggerEvent(okBtn.element);

        expect(trackingSpy).toHaveBeenCalledWith('_category_', 'click_button', {
          label: wrapper.vm.$options.trackLabel,
          property: popoverProps.humanAccess,
          value: '10',
        });
      });
    });
  });
});
