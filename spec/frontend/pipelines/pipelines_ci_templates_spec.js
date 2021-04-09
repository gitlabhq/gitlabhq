import { shallowMount } from '@vue/test-utils';
import PipelinesCiTemplate from '~/pipelines/components/pipelines_list/pipelines_ci_templates.vue';
import { SUGGESTED_CI_TEMPLATES } from '~/pipelines/constants';

const addCiYmlPath = "/-/new/master?commit_message='Add%20.gitlab-ci.yml'";

describe('Pipelines CI Templates', () => {
  let wrapper;

  const GlEmoji = { template: '<img/>' };

  const createWrapper = () => {
    return shallowMount(PipelinesCiTemplate, {
      provide: {
        addCiYmlPath,
      },
      stubs: {
        GlEmoji,
      },
    });
  };

  const findTestTemplateLinks = () => wrapper.findAll('[data-testid="test-template-link"]');
  const findTemplateDescriptions = () => wrapper.findAll('[data-testid="template-description"]');
  const findTemplateLinks = () => wrapper.findAll('[data-testid="template-link"]');
  const findTemplateNames = () => wrapper.findAll('[data-testid="template-name"]');
  const findTemplateLogos = () => wrapper.findAll('[data-testid="template-logo"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders test template', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('links to the hello world template', () => {
      expect(findTestTemplateLinks().at(0).attributes('href')).toBe(
        addCiYmlPath.concat('&template=Hello-World'),
      );
    });
  });

  describe('renders template list', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders all suggested templates', () => {
      const content = wrapper.text();

      const keys = Object.keys(SUGGESTED_CI_TEMPLATES);

      expect(content).toContain(...keys);
    });

    it('has the correct template name', () => {
      expect(findTemplateNames().at(0).text()).toBe('Android');
    });

    it('links to the correct template', () => {
      expect(findTemplateLinks().at(0).attributes('href')).toBe(
        addCiYmlPath.concat('&template=Android'),
      );
    });

    it('has the description of the template', () => {
      expect(findTemplateDescriptions().at(0).text()).toBe(
        'CI/CD template to test and deploy your Android project.',
      );
    });

    it('has the right logo of the template', () => {
      expect(findTemplateLogos().at(0).attributes('src')).toBe(
        '/assets/illustrations/logos/android.svg',
      );
    });
  });
});
