import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiTemplates from '~/pipelines/components/pipelines_list/empty_state/ci_templates.vue';

const pipelineEditorPath = '/-/ci/editor';
const suggestedCiTemplates = [
  { name: 'Android', logo: '/assets/illustrations/logos/android.svg' },
  { name: 'Bash', logo: '/assets/illustrations/logos/bash.svg' },
  { name: 'C++', logo: '/assets/illustrations/logos/c_plus_plus.svg' },
];

describe('CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = () => {
    return shallowMountExtended(CiTemplates, {
      provide: {
        pipelineEditorPath,
        suggestedCiTemplates,
      },
    });
  };

  const findTemplateDescription = () => wrapper.findByTestId('template-description');
  const findTemplateLink = () => wrapper.findByTestId('template-link');
  const findTemplateName = () => wrapper.findByTestId('template-name');
  const findTemplateLogo = () => wrapper.findByTestId('template-logo');

  beforeEach(() => {
    wrapper = createWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('renders template list', () => {
    it('renders all suggested templates', () => {
      const content = wrapper.text();

      expect(content).toContain('Android', 'Bash', 'C++');
    });

    it('has the correct template name', () => {
      expect(findTemplateName().text()).toBe('Android');
    });

    it('links to the correct template', () => {
      expect(findTemplateLink().attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Android'),
      );
    });

    it('has the description of the template', () => {
      expect(findTemplateDescription().text()).toBe(
        'CI/CD template to test and deploy your Android project.',
      );
    });

    it('has the right logo of the template', () => {
      expect(findTemplateLogo().attributes('src')).toBe('/assets/illustrations/logos/android.svg');
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
    });

    it('sends an event when template is clicked', () => {
      findTemplateLink().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
        label: 'Android',
      });
    });
  });
});
