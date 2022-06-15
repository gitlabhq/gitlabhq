import { GlButton, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import CiValidate, { i18n } from '~/pipeline_editor/components/validate/ci_validate.vue';

describe('Pipeline Editor Validate Tab', () => {
  let wrapper;

  const createComponent = ({ stubs } = {}) => {
    wrapper = shallowMount(CiValidate, {
      provide: {
        validateTabIllustrationPath: '/path/to/img',
      },
      stubs,
    });
  };

  const findCta = () => wrapper.findComponent(GlButton);
  const findPipelineSource = () => wrapper.findComponent(GlDropdown);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders disabled pipeline source dropdown', () => {
      expect(findPipelineSource().exists()).toBe(true);
      expect(findPipelineSource().attributes('text')).toBe(i18n.pipelineSourceDefault);
      expect(findPipelineSource().attributes('disabled')).toBe('true');
    });

    it('renders CTA', () => {
      expect(findCta().exists()).toBe(true);
      expect(findCta().text()).toBe(i18n.cta);
    });
  });
});
