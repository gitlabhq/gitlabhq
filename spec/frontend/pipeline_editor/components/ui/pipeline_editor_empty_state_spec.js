import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineEditorEmptyState from '~/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';

describe('Pipeline editor empty state', () => {
  let wrapper;
  const defaultProvide = {
    emptyStateIllustrationPath: 'my/svg/path',
  };

  const createComponent = () => {
    wrapper = shallowMount(PipelineEditorEmptyState, {
      provide: defaultProvide,
    });
  };

  const findSvgImage = () => wrapper.find('img');
  const findTitle = () => wrapper.find('h1');
  const findDescription = () => wrapper.findComponent(GlSprintf);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders an svg image', () => {
    expect(findSvgImage().exists()).toBe(true);
  });

  it('renders a title', () => {
    expect(findTitle().exists()).toBe(true);
    expect(findTitle().text()).toBe(wrapper.vm.$options.i18n.title);
  });

  it('renders a description', () => {
    expect(findDescription().exists()).toBe(true);
    expect(findDescription().html()).toContain(wrapper.vm.$options.i18n.body);
  });
});
