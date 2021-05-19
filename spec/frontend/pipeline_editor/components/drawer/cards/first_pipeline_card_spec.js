import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import FirstPipelineCard from '~/pipeline_editor/components/drawer/cards/first_pipeline_card.vue';
import PipelineVisualReference from '~/pipeline_editor/components/drawer/ui/pipeline_visual_reference.vue';

describe('First pipeline card', () => {
  let wrapper;

  const defaultProvide = {
    ciExamplesHelpPagePath: '/pipelines/examples',
    runnerHelpPagePath: '/help/runners',
  };

  const createComponent = () => {
    wrapper = mount(FirstPipelineCard, {
      provide: {
        ...defaultProvide,
      },
    });
  };

  const getLinkByName = (name) => getByRole(wrapper.element, 'link', { name }).href;
  const findPipelinesLink = () => getLinkByName(/examples and templates/i);
  const findRunnersLink = () => getLinkByName(/make sure your instance has runners available/i);
  const findVisualReference = () => wrapper.findComponent(PipelineVisualReference);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.title);
  });

  it('renders the content', () => {
    expect(findVisualReference().exists()).toBe(true);
  });

  it('renders the links', () => {
    expect(findRunnersLink()).toContain(defaultProvide.runnerHelpPagePath);
    expect(findPipelinesLink()).toContain(defaultProvide.ciExamplesHelpPagePath);
  });
});
