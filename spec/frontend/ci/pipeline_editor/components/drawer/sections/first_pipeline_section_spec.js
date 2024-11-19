import { GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import FirstPipelineSection from '~/ci/pipeline_editor/components/drawer/sections/first_pipeline_section.vue';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';

describe('First pipeline section', () => {
  let wrapper;
  let trackingSpy;

  const createComponent = () => {
    wrapper = mountExtended(FirstPipelineSection, {
      stubs: ['gl-emoji'],
    });
  };

  const findInstructionsList = () => wrapper.find('ol');
  const findAllInstructions = () => findInstructionsList().findAll('li');
  const findLink = () => wrapper.findComponent(GlLink);
  const findSectionComponent = () => wrapper.findComponent(SectionComponent);

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji and title', () => {
    expect(findSectionComponent().exists()).toBe(true);
    expect(findSectionComponent().props()).toMatchObject({
      emoji: 'rocket',
      title: 'Run your first pipeline',
    });
  });

  it('renders the content', () => {
    expect(findInstructionsList().exists()).toBe(true);
    expect(findAllInstructions()).toHaveLength(3);
  });

  it('renders the link', () => {
    expect(findLink().attributes('href')).toBe(wrapper.vm.$options.RUNNER_HELP_URL);
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('tracks runners help page click', async () => {
      const { label } = pipelineEditorTrackingOptions;
      const { runners } = pipelineEditorTrackingOptions.actions.helpDrawerLinks;

      await findLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, runners, { label });
    });
  });
});
