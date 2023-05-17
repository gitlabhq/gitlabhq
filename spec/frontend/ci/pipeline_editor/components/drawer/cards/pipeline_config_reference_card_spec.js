import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import PipelineConfigReferenceCard from '~/ci/pipeline_editor/components/drawer/cards/pipeline_config_reference_card.vue';
import { pipelineEditorTrackingOptions } from '~/ci/pipeline_editor/constants';

describe('Pipeline config reference card', () => {
  let wrapper;
  let trackingSpy;

  const defaultProvide = {
    ciExamplesHelpPagePath: 'help/ci/examples/',
    ciHelpPagePath: 'help/ci/introduction',
    needsHelpPagePath: 'help/ci/yaml#needs',
    ymlHelpPagePath: 'help/ci/yaml',
  };

  const createComponent = () => {
    wrapper = mount(PipelineConfigReferenceCard, {
      provide: {
        ...defaultProvide,
      },
    });
  };

  const getLinkByName = (name) => getByRole(wrapper.element, 'link', { name });
  const findCiExamplesLink = () => getLinkByName(/CI\/CD examples and templates/i);
  const findCiIntroLink = () => getLinkByName(/GitLab CI\/CD concepts/i);
  const findNeedsLink = () => getLinkByName(/Needs keyword/i);
  const findYmlSyntaxLink = () => getLinkByName(/.gitlab-ci.yml syntax reference/i);

  beforeEach(() => {
    createComponent();
  });

  it('renders the title', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.title);
  });

  it('renders the content', () => {
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });

  it('renders the links', () => {
    expect(findCiExamplesLink().href).toContain(defaultProvide.ciExamplesHelpPagePath);
    expect(findCiIntroLink().href).toContain(defaultProvide.ciHelpPagePath);
    expect(findNeedsLink().href).toContain(defaultProvide.needsHelpPagePath);
    expect(findYmlSyntaxLink().href).toContain(defaultProvide.ymlHelpPagePath);
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

      await element.click();

      expect(trackingSpy).toHaveBeenCalledWith(undefined, expectedAction, {
        label,
      });
    };

    it('tracks help page links', () => {
      const {
        CI_EXAMPLES_LINK,
        CI_HELP_LINK,
        CI_NEEDS_LINK,
        CI_YAML_LINK,
      } = pipelineEditorTrackingOptions.actions.helpDrawerLinks;

      testTracker(findCiExamplesLink(), CI_EXAMPLES_LINK);
      testTracker(findCiIntroLink(), CI_HELP_LINK);
      testTracker(findNeedsLink(), CI_NEEDS_LINK);
      testTracker(findYmlSyntaxLink(), CI_YAML_LINK);
    });
  });
});
