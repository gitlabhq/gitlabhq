import { mountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelineConfigReferenceSection from '~/ci/pipeline_editor/components/drawer/sections/pipeline_config_reference_section.vue';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';
import SectionComponent from '~/ci/pipeline_editor/components/drawer/pipeline_editor_drawer_section.vue';

describe('Pipeline config reference section', () => {
  let wrapper;
  let trackingSpy;

  const defaultProvide = {
    ciExamplesHelpPagePath: 'help/ci/examples/',
    ciHelpPagePath: 'help/ci/introduction',
    needsHelpPagePath: 'help/ci/yaml#needs',
    ymlHelpPagePath: 'help/ci/yaml',
  };

  const createComponent = () => {
    wrapper = mountExtended(PipelineConfigReferenceSection, {
      provide: {
        ...defaultProvide,
      },
      stubs: ['gl-emoji'],
    });
  };

  const findCiExamplesLink = () => wrapper.findByTestId('ci-examples-link');
  const findCiHelpLink = () => wrapper.findByTestId('ci-help-link');
  const findCiNeedsLink = () => wrapper.findByTestId('ci-needs-link');
  const findCiYamlLink = () => wrapper.findByTestId('ci-yaml-link');
  const findSectionComponent = () => wrapper.findComponent(SectionComponent);

  beforeEach(() => {
    createComponent();
  });

  it('assigns the correct emoji and title', () => {
    expect(findSectionComponent().exists()).toBe(true);
    expect(findSectionComponent().props()).toMatchObject({
      emoji: 'gear',
      title: 'Pipeline configuration reference',
    });
  });

  it('renders the content', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });

  it('renders the links', () => {
    expect(findCiExamplesLink().attributes('href')).toContain(
      defaultProvide.ciExamplesHelpPagePath,
    );
    expect(findCiHelpLink().attributes('href')).toContain(defaultProvide.ciHelpPagePath);
    expect(findCiNeedsLink().attributes('href')).toContain(defaultProvide.needsHelpPagePath);
    expect(findCiYamlLink().attributes('href')).toContain(defaultProvide.ymlHelpPagePath);
  });

  describe('tracking', () => {
    beforeEach(() => {
      createComponent();
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    const testTracker = async (element, expectedAction) => {
      const { label } = pipelineEditorTrackingOptions;

      await element.vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledWith(undefined, expectedAction, {
        label,
      });
    };

    it('tracks help page links', () => {
      const { CI_EXAMPLES_LINK, CI_HELP_LINK, CI_NEEDS_LINK, CI_YAML_LINK } =
        pipelineEditorTrackingOptions.actions.helpDrawerLinks;

      testTracker(findCiExamplesLink(), CI_EXAMPLES_LINK);
      testTracker(findCiHelpLink(), CI_HELP_LINK);
      testTracker(findCiNeedsLink(), CI_NEEDS_LINK);
      testTracker(findCiYamlLink(), CI_YAML_LINK);
    });
  });
});
