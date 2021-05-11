import { getByRole } from '@testing-library/dom';
import { mount } from '@vue/test-utils';
import PipelineConfigReferenceCard from '~/pipeline_editor/components/drawer/cards/pipeline_config_reference_card.vue';

describe('Pipeline config reference card', () => {
  let wrapper;

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

  const getLinkByName = (name) => getByRole(wrapper.element, 'link', { name }).href;
  const findCiExamplesLink = () => getLinkByName(/CI\/CD examples and templates/i);
  const findCiIntroLink = () => getLinkByName(/GitLab CI\/CD concepts/i);
  const findNeedsLink = () => getLinkByName(/Needs keyword/i);
  const findYmlSyntaxLink = () => getLinkByName(/.gitlab-ci.yml syntax reference/i);

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
    expect(wrapper.text()).toContain(wrapper.vm.$options.i18n.firstParagraph);
  });

  it('renders the links', () => {
    expect(findCiExamplesLink()).toContain(defaultProvide.ciExamplesHelpPagePath);
    expect(findCiIntroLink()).toContain(defaultProvide.ciHelpPagePath);
    expect(findNeedsLink()).toContain(defaultProvide.needsHelpPagePath);
    expect(findYmlSyntaxLink()).toContain(defaultProvide.ymlHelpPagePath);
  });
});
