import { mount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import suggestPipelineComponent from '~/vue_merge_request_widget/components/mr_widget_suggest_pipeline.vue';
import MrWidgetIcon from '~/vue_merge_request_widget/components/mr_widget_icon.vue';

describe('MRWidgetHeader', () => {
  let wrapper;
  const pipelinePath = '/foo/bar/add/pipeline/path';
  const iconName = 'status_notfound';

  beforeEach(() => {
    wrapper = mount(suggestPipelineComponent, {
      propsData: { pipelinePath },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders add pipeline file link', () => {
      const link = wrapper.find(GlLink);

      return wrapper.vm.$nextTick().then(() => {
        expect(link.exists()).toBe(true);
        expect(link.attributes().href).toBe(pipelinePath);
      });
    });

    it('renders the expected text', () => {
      const messageText = /\s*No pipeline\s*Add the .gitlab-ci.yml file\s*to create one./;

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.text()).toMatch(messageText);
      });
    });

    it('renders widget icon', () => {
      const icon = wrapper.find(MrWidgetIcon);

      return wrapper.vm.$nextTick().then(() => {
        expect(icon.exists()).toBe(true);
        expect(icon.props()).toEqual(
          expect.objectContaining({
            name: iconName,
          }),
        );
      });
    });
  });
});
