import { shallowMount } from '@vue/test-utils';
import PipelinesCiTemplate from '~/pipelines/components/pipelines_list/pipelines_ci_templates.vue';
import { SUGGESTED_CI_TEMPLATES } from '~/pipelines/constants';

const addCiYmlPath = "/-/new/master?commit_message='Add%20.gitlab-ci.yml'";

describe('Pipelines CI Templates', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(PipelinesCiTemplate, {
      provide: {
        addCiYmlPath,
      },
    });
  };

  const findTemplateDescriptions = () => wrapper.findAll('[data-testid="template-description"]');
  const findTemplateLinks = () => wrapper.findAll('[data-testid="template-link"]');
  const findTemplateLogos = () => wrapper.findAll('[data-testid="template-logo"]');

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders templates', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('renders all suggested templates', () => {
      const content = wrapper.text();

      const keys = Object.keys(SUGGESTED_CI_TEMPLATES);

      expect(content).toContain(...keys);
    });

    it('links to the correct template', () => {
      expect(findTemplateLinks().at(0).attributes('href')).toEqual(
        addCiYmlPath.concat('&template=Android'),
      );
    });

    it('has the description of the template', () => {
      expect(findTemplateDescriptions().at(0).text()).toEqual(
        'Continuous deployment template to test and deploy your Android project.',
      );
    });

    it('has the right logo of the template', () => {
      expect(findTemplateLogos().at(0).attributes('src')).toEqual(
        '/assets/illustrations/logos/android.svg',
      );
    });
  });
});
