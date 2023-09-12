import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import CiTemplates from '~/ci/pipelines_page/components/empty_state/ci_templates.vue';

const pipelineEditorPath = '/-/ci/editor';
const suggestedCiTemplates = [
  { name: 'Android', logo: '/assets/illustrations/logos/android.svg' },
  { name: 'Bash', logo: '/assets/illustrations/logos/bash.svg' },
  { name: 'C++', logo: '/assets/illustrations/logos/c_plus_plus.svg' },
];

describe('CI Templates', () => {
  let wrapper;
  let trackingSpy;

  const createWrapper = (propsData = {}) => {
    wrapper = shallowMountExtended(CiTemplates, {
      provide: {
        pipelineEditorPath,
        suggestedCiTemplates,
      },
      propsData,
    });
  };

  const findTemplateDescription = () => wrapper.findByTestId('template-description');
  const findTemplateLink = () => wrapper.findByTestId('template-link');
  const findTemplateNames = () => wrapper.findAllByTestId('template-name');
  const findTemplateName = () => wrapper.findByTestId('template-name');
  const findTemplateLogo = () => wrapper.findByTestId('template-logo');

  describe('renders template list', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders all suggested templates', () => {
      expect(findTemplateNames().length).toBe(3);
      expect(wrapper.text()).toContain('Android', 'Bash', 'C++');
    });

    it('has the correct template name', () => {
      expect(findTemplateName().text()).toBe('Android');
    });

    it('links to the correct template', () => {
      expect(findTemplateLink().attributes('href')).toBe(
        pipelineEditorPath.concat('?template=Android'),
      );
    });

    it('has the link button enabled', () => {
      expect(findTemplateLink().props('disabled')).toBe(false);
    });

    it('has the description of the template', () => {
      expect(findTemplateDescription().text()).toBe(
        'Continuous integration and deployment template to test and deploy your Android project.',
      );
    });

    it('has the right logo of the template', () => {
      expect(findTemplateLogo().attributes('src')).toBe('/assets/illustrations/logos/android.svg');
    });
  });

  describe('filtering the templates', () => {
    beforeEach(() => {
      createWrapper({ filterTemplates: ['Bash'] });
    });

    it('renders only the filtered templates', () => {
      expect(findTemplateNames()).toHaveLength(1);
      expect(findTemplateName().text()).toBe('Bash');
    });
  });

  describe('disabling the templates', () => {
    beforeEach(() => {
      createWrapper({ disabled: true });
    });

    it('has the link button disabled', () => {
      expect(findTemplateLink().props('disabled')).toBe(true);
    });
  });

  describe('tracking', () => {
    beforeEach(() => {
      createWrapper();
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
