import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import suggestPipelineComponent from '~/vue_merge_request_widget/components/mr_widget_suggest_pipeline.vue';
import stubChildren from 'helpers/stub_children';
import PipelineTourState from '~/vue_merge_request_widget/components/states/mr_widget_pipeline_tour.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';
import { mockTracking, triggerEvent, unmockTracking } from 'helpers/tracking_helper';

describe('MRWidgetHeader', () => {
  let wrapper;
  const pipelinePath = '/foo/bar/add/pipeline/path';
  const pipelineSvgPath = '/foo/bar/pipeline/svg/path';
  const humanAccess = 'maintainer';
  const iconName = 'status_notfound';

  beforeEach(() => {
    wrapper = mount(suggestPipelineComponent, {
      propsData: { pipelinePath, pipelineSvgPath, humanAccess },
      stubs: {
        ...stubChildren(PipelineTourState),
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders add pipeline file link', () => {
      const link = wrapper.find(GlLink);

      expect(link.exists()).toBe(true);
      expect(link.attributes().href).toBe(pipelinePath);
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

    describe('tracking', () => {
      let spy;

      beforeEach(() => {
        spy = mockTracking('_category_', wrapper.element, jest.spyOn);
      });

      afterEach(() => {
        unmockTracking();
      });

      it('send an event when ok button is clicked', () => {
        const link = wrapper.find(GlLink);
        triggerEvent(link.element);

        expect(spy).toHaveBeenCalledWith('_category_', 'click_link', {
          label: 'no_pipeline_noticed',
          property: humanAccess,
          value: '30',
        });
      });
    });
  });
});
